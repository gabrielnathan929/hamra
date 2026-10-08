# Firewall with iptables — A Practical Guide

## Table of Contents

- [Basic Concepts](#basic-concepts)
- [iptables Structure](#iptables-structure)
- [Real Case: Opening a Port for External Access](#real-case-opening-a-port-for-external-access)
- [Essential Commands](#essential-commands)
- [Common Scenarios](#common-scenarios)
- [Rule Persistence](#rule-persistence)
- [Troubleshooting](#troubleshooting)

---

## Basic Concepts

iptables is a Linux packet-filtering firewall. It organizes rules into **chains** inside **tables**. The most used table is `filter`, which controls whether a packet passes or gets blocked.

### Main tables

| Table | Function |
|---|---|
| `filter` | Packet filtering (ACCEPT, REJECT, DROP) |
| `nat` | Address translation (NAT, redirection) |
| `mangle` | Packet header modification |

> 95% of day-to-day cases use only the `filter` table.

### Default chains of the filter table

| Chain | Direction | Description |
|---|---|---|
| `INPUT` | Packets **received** by the server | Server access control |
| `OUTPUT` | Packets **sent** by the server | Outbound traffic control |
| `FORWARD` | Packets **forwarded** by the server | Routing |

### Targets

| Target | Effect |
|---|---|
| `ACCEPT` | Allows the packet |
| `DROP` | Discards the packet (no response) |
| `REJECT` | Rejects the packet (responds with an error) |
| `LOG` | Logs the packet |
| `RETURN` | Returns to the previous chain |

---

## iptables Structure

Rules are evaluated in **sequential order**, top to bottom. The first rule that matches the packet is executed. If no rule matches, the chain's **default policy** is applied.

```
START
  │
  ├── Rule 1: matches? ──YES──> ACTION (ACCEPT/DROP/...)
  │
  ├── Rule 2: matches? ──YES──> ACTION
  │
  ├── ...
  │
  └── None? ──> DEFAULT POLICY
```

> **Rule order is critical.** A DROP rule at the beginning prevents any ACCEPT rule below it from running for that traffic.

### Example of a real structure

```
Chain INPUT (policy ACCEPT)
target     prot opt source         destination
fw-custom  all  --  0.0.0.0/0      0.0.0.0/0       ← jumps to a custom chain

Chain fw-custom
accept-all     all    --  0.0.0.0/0      0.0.0.0/0
accept-all     all    --  0.0.0.0/0      0.0.0.0/0       ctstate RELATED,ESTABLISHED
accept-all     tcp    --  0.0.0.0/0      0.0.0.0/0       tcp dpt:22
log-and-refuse all    --  0.0.0.0/0      0.0.0.0/0       ← catches everything not accepted
refuse-all     all    --  0.0.0.0/0      0.0.0.0/0       ← final DROP

Chain accept-all (multiple references)
ACCEPT     all  --  0.0.0.0/0      0.0.0.0/0

Chain refuse-all (multiple references)
DROP       all  --  0.0.0.0/0      0.0.0.0/0
```

---

## Real Case: Opening a Port for External Access

### Problem

A web server (Go, Node, Python, etc.) runs on port `8080` and is reachable via `localhost`, but external devices on the same network (phone, another PC) get `ERR_TIMED_OUT`.

### Cause

The firewall blocks incoming TCP connections on port `8080`. Local `curl` works because the firewall doesn't block connections originating from the machine itself (they go through `OUTPUT`, not `INPUT`).

### Diagnosis

```bash
# Check whether the server is listening on the right port
# *:PORT means it listens on all interfaces
ss -tlnp | grep 8080
# Example output: LISTEN 0 4096 *:8080 *:* users:(("main",pid=1234,fd=4))

# List firewall rules
iptables -L -n --line-numbers

# Focus on the INPUT chain and sub-chains
iptables -L INPUT -n --line-numbers
```

### Solution

```bash
# Open a TCP port for any source
sudo iptables -I INPUT <POSITION> -p tcp --dport 8080 -j ACCEPT

# Example: insert at position 1 (before any restrictive rule)
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
```

### Common mistake

Adding the rule at the **end** of the chain with `-A` instead of inserting it with `-I`. If the chain has a DROP rule at the end, the rule added after it is never reached:

```bash
# WRONG: the rule lands after the DROP and never runs
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# CORRECT: insert before the DROP rule
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
```

---

## Essential Commands

### Viewing

```bash
# List rules with line numbers (useful for diagnosis)
sudo iptables -L -n --line-numbers

# List only the INPUT chain
sudo iptables -L INPUT -n --line-numbers

# List with traffic volume (-v)
sudo iptables -L -n -v

# See rules in command format (restorable)
sudo iptables-save
```

### Rule management

```bash
# Insert rule at a specific position
sudo iptables -I <CHAIN> <POSITION> -p <PROTO> --dport <PORT> -j <ACTION>

# Add rule at the end of the chain
sudo iptables -A <CHAIN> -p <PROTO> --dport <PORT> -j <ACTION>

# Remove rule by number
sudo iptables -D <CHAIN> <NUMBER>

# Remove rule by exact match
sudo iptables -D <CHAIN> -p <PROTO> --dport <PORT> -j <ACTION>

# Replace a rule at a position
sudo iptables -R <CHAIN> <NUMBER> -p <PROTO> --dport <PORT> -j <ACTION>

# Flush all rules from the filter table
sudo iptables -F

# Flush just one chain
sudo iptables -F <CHAIN>
```

### Flags (parameters)

| Flag | Meaning | Example |
|---|---|---|
| `-p` | Protocol | `tcp`, `udp`, `icmp`, `all` |
| `--dport` | Destination port | `8080`, `22`, `3000:3100` (range) |
| `--sport` | Source port | `1024:65535` |
| `-s` | Source IP/CIDR | `192.168.1.100`, `10.0.0.0/24` |
| `-d` | Destination IP/CIDR | `0.0.0.0/0` (all) |
| `-i` | Inbound interface | `eth0`, `wlp0s20f3` |
| `-o` | Outbound interface | `eth0` |
| `-j` | Target | `ACCEPT`, `DROP`, `REJECT` |
| `-I` | Insert at position | `-I INPUT 3` |
| `-A` | Append to end | `-A INPUT` |
| `-D` | Delete | `-D INPUT 5` |
| `-R` | Replace | `-R INPUT 3` |
| `-F` | Flush | `-F INPUT` |
| `--line-numbers` | Show numbers | `-L -n --line-numbers` |
| `-n` | DNS resolution off | `-L -n` (faster) |
| `-v` | Verbose (counters) | `-L -n -v` |

---

## Common Scenarios

### 1. Open a TCP port for any source

```bash
sudo iptables -I INPUT 1 -p tcp --dport 3000 -j ACCEPT
```

### 2. Open a port only for a specific IP

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8080 -s 192.168.1.100 -j ACCEPT
```

### 3. Open for an entire subnet

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8080 -s 192.168.1.0/24 -j ACCEPT
```

### 4. Block a specific IP

```bash
sudo iptables -I INPUT 1 -s 10.0.0.50 -j DROP
```

### 5. Open a range of ports

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8000:8100 -j ACCEPT
```

### 6. Open a UDP port

```bash
sudo iptables -I INPUT 1 -p udp --dport 5353 -j ACCEPT
```

### 7. Open only for a specific interface

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8080 -i wlp0s20f3 -j ACCEPT
```

### 8. Check whether the port is reachable from outside

```bash
# Local test
curl http://localhost:8080

# Test via the network interface's IP
curl http://192.168.1.9:8080

# From another device on the same network
# curl http://<SERVER_IP>:<PORT>
```

---

## Rule Persistence

Rules added manually with `iptables` are **volatile** — they disappear when the system reboots.

### Ways to persist them

#### 1. NixOS

```nix
{
  networking.firewall.allowedTCPPorts = [ 8080 3000 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];
}
```

Apply with:

```bash
sudo nixos-rebuild switch
```

#### 2. iptables-persistent (Debian/Ubuntu)

```bash
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

#### 3. Startup script (any distro)

Save the rules:

```bash
sudo iptables-save > /etc/iptables.rules
```

Restore at boot (via rc.local, systemd service, etc.):

```bash
sudo iptables-restore < /etc/iptables.rules
```

---

## Troubleshooting

| Symptom | Likely cause | Solution |
|---|---|---|
| `ERR_TIMED_OUT` | Firewall blocking the port | Check `iptables -L -n --line-numbers` |
| `ERR_CONNECTION_REFUSED` | Server not running or wrong port | Check `ss -tlnp \| grep <PORT>` |
| `localhost` works, IP doesn't | Firewall OR server listening only on 127.0.0.1 | Check `ss -tlnp` (should show `*:PORT`) |
| Ping works, TCP doesn't | Firewall blocking TCP | Check the iptables chains |
| Rule added but no effect | Rule sits after a DROP | Use `-I` instead of `-A` |
| `Permission denied` | Missing sudo | Use `sudo` before the command |
| `No chain/target/match by that name` | Chain or target doesn't exist | Check the name with `iptables -L` |

---

## Quick Flow Diagram

```
Packet arrives at the server
          │
          ▼
     Chain INPUT
          │
          ├── ACCEPT rule? ──YES──> PACKET ACCEPTED
          │
          ├── DROP rule? ──YES──> PACKET DROPPED
          │
          ├── Next rule...
          │
          └── End of the rules?
                  │
                  ▼
          Default policy
          ├── ACCEPT ──> PACKET ACCEPTED
          └── DROP ────> PACKET DROPPED
```
