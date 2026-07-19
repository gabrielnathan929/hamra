# Firewall com iptables — Guia Prático

## Índice

- [Conceitos Básicos](#conceitos-básicos)
- [Estrutura do iptables](#estrutura-do-iptables)
- [Caso Real: Liberar Porta para Acesso Externo](#caso-real-liberar-porta-para-acesso-externo)
- [Comandos Essenciais](#comandos-essenciais)
- [Cenários Comuns](#cenários-comuns)
- [Persistência das Regras](#persistência-das-regras)
- [Troubleshooting](#troubleshooting)

---

## Conceitos Básicos

iptables é um firewall de filtro de pacotes do Linux. Ele organiza regras em **chains** (cadeias) dentro de **tables** (tabelas). A tabela mais usada é a `filter`, que controla se um pacote passa ou é bloqueado.

### Tables principais

| Tabela | Função |
|---|---|
| `filter` | Filtro de pacotes (ACEITAR, REJEITAR, DROPAR) |
| `nat` | Tradução de endereços (NAT, redirecionamento) |
| `mangle` | Modificação de cabeçalhos dos pacotes |

> 95% dos casos do dia a dia usam apenas a tabela `filter`.

### Chains padrão da tabela filter

| Chain | Direção | Descrição |
|---|---|---|
| `INPUT` | Pacotes **recebidos** pelo servidor | Controle de acesso ao servidor |
| `OUTPUT` | Pacotes **enviados** pelo servidor | Liberação de saída |
| `FORWARD` | Pacotes **encaminhados** pelo servidor | Roteamento |

### Alvos (targets)

| Alvo | Efeito |
|---|---|
| `ACCEPT` | Permite o pacote |
| `DROP` | Descarta o pacote (sem resposta) |
| `REJECT` | Rejeita o pacote (responde com erro) |
| `LOG` | Registra o pacote nos logs |
| `RETURN` | Volta para a chain anterior |

---

## Estrutura do iptables

As regras são avaliadas em **ordem sequencial**, de cima para baixo. A primeira regra que corresponde ao pacote é executada. Se nenhuma regra corresponder, a **política padrão** (default policy) da chain é aplicada.

```
INÍCIO
  │
  ├── Regra 1: corresponde? ──SIM──> AÇÃO (ACCEPT/DROP/...)
  │
  ├── Regra 2: corresponde? ──SIM──> AÇÃO
  │
  ├── ...
  │
  └── Nenhuma? ──> POLÍTICA PADRÃO
```

> **A ordem das regras é crítica.** Uma regra de DROP no começo impede que qualquer regra de ACCEPT abaixo dela seja executada para aquele tráfego.

### Exemplo de estrutura real

```
Chain INPUT (policy ACCEPT)
target     prot opt source         destination
fw-custom  all  --  0.0.0.0/0      0.0.0.0/0       ← pula para chain personalizada

Chain fw-custom
accept-all     all    --  0.0.0.0/0      0.0.0.0/0
accept-all     all    --  0.0.0.0/0      0.0.0.0/0       ctstate RELATED,ESTABLISHED
accept-all     tcp    --  0.0.0.0/0      0.0.0.0/0       tcp dpt:22
log-and-refuse all    --  0.0.0.0/0      0.0.0.0/0       ← captura tudo que não foi aceito
refuse-all     all    --  0.0.0.0/0      0.0.0.0/0       ← DROP final

Chain accept-all (várias referências)
ACCEPT     all  --  0.0.0.0/0      0.0.0.0/0

Chain refuse-all (várias referências)
DROP       all  --  0.0.0.0/0      0.0.0.0/0
```

---

## Caso Real: Liberar Porta para Acesso Externo

### Problema

Um servidor web (Go, Node, Python, etc.) roda na porta `8080` e está acessível via `localhost`, mas dispositivos externos na mesma rede (celular, outro PC) recebem `ERR_TIMED_OUT`.

### Causa

O firewall bloqueia conexões TCP de entrada na porta `8080`. O `curl` local funciona porque o firewall não bloqueia conexões originadas da própria máquina (elas passam pelo `OUTPUT`, não pelo `INPUT`).

### Diagnóstico

```bash
# Verificar se o servidor está escutando na porta correta
# O *:PORTA significa que escuta em todas as interfaces
ss -tlnp | grep 8080
# Exemplo de saída: LISTEN 0 4096 *:8080 *:* users:(("main",pid=1234,fd=4))

# Listar regras do firewall
iptables -L -n --line-numbers

# Foco no chain INPUT e sub-chains
iptables -L INPUT -n --line-numbers
```

### Solução

```bash
# Liberar porta TCP para qualquer origem
sudo iptables -I INPUT <POSICAO> -p tcp --dport 8080 -j ACCEPT

# Exemplo: inserir na posição 1 (antes de qualquer regra restritiva)
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
```

### Erro comum

Adicionar a regra no **final** da chain com `-A` em vez de inserir com `-I`. Se a chain tem uma regra de DROP no final, a regra adicionada depois nunca é alcançada:

```bash
# ERRADO: regra fica depois do DROP e nunca é executada
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# CORRETO: inserir antes da regra de DROP
sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
```

---

## Comandos Essenciais

### Visualização

```bash
# Listar regras com números de linha (útil para diagnóstico)
sudo iptables -L -n --line-numbers

# Listar apenas o chain INPUT
sudo iptables -L INPUT -n --line-numbers

# Listar com volume de tráfego (-v)
sudo iptables -L -n -v

# Ver regras em formato de comando (restaurável)
sudo iptables-save
```

### Gerenciamento de regras

```bash
# Inserir regra em posição específica
sudo iptables -I <CHAIN> <POSICAO> -p <PROTO> --dport <PORTA> -j <ACAO>

# Adicionar regra no final da chain
sudo iptables -A <CHAIN> -p <PROTO> --dport <PORTA> -j <ACAO>

# Remover regra por número
sudo iptables -D <CHAIN> <NUMERO>

# Remover regra por correspondência exata
sudo iptables -D <CHAIN> -p <PROTO> --dport <PORTA> -j <ACAO>

# Substituir regra em uma posição
sudo iptables -R <CHAIN> <NUMERO> -p <PROTO> --dport <PORTA> -j <ACAO>

# Limpar todas as regras da tabela filter
sudo iptables -F

# Limpar apenas uma chain
sudo iptables -F <CHAIN>
```

### Flags (parâmetros)

| Flag | Significado | Exemplo |
|---|---|---|
| `-p` | Protocolo | `tcp`, `udp`, `icmp`, `all` |
| `--dport` | Porta de destino | `8080`, `22`, `3000:3100` (range) |
| `--sport` | Porta de origem | `1024:65535` |
| `-s` | IP/CIDR de origem | `192.168.1.100`, `10.0.0.0/24` |
| `-d` | IP/CIDR de destino | `0.0.0.0/0` (todos) |
| `-i` | Interface de entrada | `eth0`, `wlp0s20f3` |
| `-o` | Interface de saída | `eth0` |
| `-j` | Alvo (target) | `ACCEPT`, `DROP`, `REJECT` |
| `-I` | Inserir em posição | `-I INPUT 3` |
| `-A` | Adicionar ao final | `-A INPUT` |
| `-D` | Deletar | `-D INPUT 5` |
| `-R` | Substituir | `-R INPUT 3` |
| `-F` | Limpar (flush) | `-F INPUT` |
| `--line-numbers` | Mostrar números | `-L -n --line-numbers` |
| `-n` | Resolução DNS desligada | `-L -n` (mais rápido) |
| `-v` | Verboso (contadores) | `-L -n -v` |

---

## Cenários Comuns

### 1. Liberar uma porta TCP para qualquer origem

```bash
sudo iptables -I INPUT 1 -p tcp --dport 3000 -j ACCEPT
```

### 2. Liberar uma porta apenas para um IP específico

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8080 -s 192.168.1.100 -j ACCEPT
```

### 3. Liberar para uma sub-rede inteira

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8080 -s 192.168.1.0/24 -j ACCEPT
```

### 4. Bloquear um IP específico

```bash
sudo iptables -I INPUT 1 -s 10.0.0.50 -j DROP
```

### 5. Liberar um range de portas

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8000:8100 -j ACCEPT
```

### 6. Liberar porta UDP

```bash
sudo iptables -I INPUT 1 -p udp --dport 5353 -j ACCEPT
```

### 7. Liberar apenas para uma interface específica

```bash
sudo iptables -I INPUT 1 -p tcp --dport 8080 -i wlp0s20f3 -j ACCEPT
```

### 8. Verificar se a porta está acessível de fora

```bash
# Teste local
curl http://localhost:8080

# Teste pelo IP da interface de rede
curl http://192.168.1.9:8080

# De outro dispositivo na mesma rede
# curl http://<IP_DO_SERVIDOR>:<PORTA>
```

---

## Persistência das Regras

Regras adicionadas com `iptables` manualmente são **voláteis** — desaparecem ao reiniciar o sistema.

### Formas de persistir

#### 1. NixOS

```nix
{
  networking.firewall.allowedTCPPorts = [ 8080 3000 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];
}
```

Aplicar com:

```bash
sudo nixos-rebuild switch
```

#### 2. iptables-persistent (Debian/Ubuntu)

```bash
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

#### 3. Script de inicialização (qualquer distro)

Salvar as regras:

```bash
sudo iptables-save > /etc/iptables.rules
```

Restaurar no boot (via rc.local, systemd service, etc.):

```bash
sudo iptables-restore < /etc/iptables.rules
```

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `ERR_TIMED_OUT` | Firewall bloqueando a porta | Verificar `iptables -L -n --line-numbers` |
| `ERR_CONNECTION_REFUSED` | Servidor não rodando ou porta errada | Verificar `ss -tlnp \| grep <PORTA>` |
| `localhost` funciona, IP não | Firewall OU servidor escutando só em 127.0.0.1 | Verificar `ss -tlnp` (deve mostrar `*:PORTA`) |
| Ping funciona, TCP não | Firewall bloqueando TCP | Verificar chains do iptables |
| Regra adicionada mas sem efeito | Regra está depois de um DROP | Usar `-I` em vez de `-A` |
| `Permission denied` | Falta sudo | Usar `sudo` antes do comando |
| `No chain/target/match by that name` | Chain ou target não existe | Verificar nome com `iptables -L` |

---

## Diagrama de Fluxo rápido

```
Pacote chega ao servidor
         │
         ▼
    Chain INPUT
         │
         ├── Regra ACCEPT? ──SIM──> PACOTE ACEITO
         │
         ├── Regra DROP? ──SIM──> PACOTE DESCARTADO
         │
         ├── Próxima regra...
         │
         └── Fim das regras?
                 │
                 ▼
         Política padrão (policy)
         ├── ACCEPT ──> PACOTE ACEITO
         └── DROP ────> PACOTE DESCARTADO
```
