# SOPS Secrets Management

## Visão Geral

O Hamra usa **sops-nix** para gerenciar segredos criptografados com **age**. Os segredos ficam em `secrets/*.yaml` (criptografados) e são descriptografados automaticamente no boot/activation para `/run/secrets/`.

---

## Estrutura

```
secrets/
├── vnc.yaml       # Senha do wayvnc (VNC)
└── samba.yaml     # Senha do Samba NAS

.sops.yaml         # Configuração de chaves/recipients
```

---

## Chaves (Age)

| Tipo | Onde fica | Finalidade |
|------|-----------|------------|
| **Editing key** (privada) | `~/.config/sops/age/keys.txt` | **Apenas uma máquina** — quem edita/cria segredos (`sops secrets/...`, `sops updatekeys`) |
| **Host keys** (públicas) | `.sops.yaml` (no repo) | Cada host que precisa descriptografar — derivadas da chave SSH do host |

### Gerar chave de host
```bash
# Rode EM CADA HOST (acer, samsung, vm)
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
# Saída: age1abc... → adicione no .sops.yaml
```

### Chave de edição (gerar uma vez)
```bash
age-keygen > ~/.config/sops/age/keys.txt
# Guarde esse arquivo com segurança — ele permite descriptografar TUDO
```

---

## .sops.yaml Atual

```yaml
keys:
  # Editing key (máquina que roda sops updatekeys / sops edit)
  - &user age1sq570spnk7jm72zzyqa9h264pxulx0xqu8m2hj0ka3u27ca3uycsk3xfhu

  # Host keys (públicas — derivadas do SSH host key de cada máquina)
  - &host-samsung age1jke3vagr84utrxqsd89m3vpxmr9wgcr44tycngm4lf0570h4tsdqvr23yf
  - &host-acer    age1uw4uek9vywsw0x23hrx65pcdgqp4tmaf8pcfal54k2zct79azecq4s5qm5
  # - &host-vm age1...

creation_rules:
  # vnc.yaml: wayvnc roda no samsung E acer
  - path_regex: secrets/vnc\.yaml$
    key_groups:
      - age:
          - *user
          - *host-samsung
          - *host-acer

  # samba.yaml: NAS roda no acer, mas samsung acessa (cliente)
  - path_regex: secrets/samba\.yaml$
    key_groups:
      - age:
          - *user
          - *host-samsung
          - *host-acer
```

### Regras atuais
| Secret | Quem descriptografa | Por quê |
|--------|---------------------|---------|
| `vnc.yaml` | samsung, acer | wayvnc server rodando em ambos |
| `samba.yaml` | acer (server), samsung (cliente/activation script) | acer é o NAS; samsung roda `sync-samba-password` no activation |

---

## Fluxos Comuns

### 1. Editar um segredo (ex: mudar senha do VNC)
```bash
# Na máquina COM chave de edição (~/.config/sops/age/keys.txt)
nix develop --command sops secrets/vnc.yaml
# Abre $EDITOR com YAML descriptografado
# Salva → re-criptografa automaticamente para TODOS recipients do .sops.yaml
git add secrets/vnc.yaml && git commit -m "chore: update vnc password" && git push
```

### 2. Adicionar novo host (ex: vm)
```bash
# 1. No vm: gerar host key
ssh vm "cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age"
# → age1vm...

# 2. No repo: adicionar no .sops.yaml
#    keys: - &host-vm age1vm...
#    creation_rules: adicionar *host-vm nos secrets que o vm precisa

# 3. Na máquina com chave de edição:
nix develop --command sops updatekeys secrets/vnc.yaml secrets/samba.yaml
git add .sops.yaml secrets/*.yaml && git commit -m "chore(sops): add vm key" && git push

# 4. No vm: pull + rebuild
```

### 3. Rotacionar chave de edição (se comprometida)
```bash
# 1. Gerar nova
age-keygen > ~/.config/sops/age/keys.txt.novo
# 2. Atualizar .sops.yaml (trocar &user)
# 3. Re-encryptar tudo:
nix develop --command sops updatekeys secrets/*.yaml
git add .sops.yaml secrets/*.yaml && git commit -m "chore(sops): rotate editing key" && git push
```

### 4. Ver segredo sem editar
```bash
# Em qualquer host que consiga descriptografar (tem sua host key no .sops.yaml)
nix develop --command sops -d secrets/vnc.yaml
```

---

## Como Funciona no Boot (sops-nix)

1. `configuration.nix` importa `sops-nix` module
2. `sops.secrets.<name>` define:
   - `sopsFile` = `secrets/...yaml`
   - `owner` / `mode` / `group`
3. No **activation** (antes do switch):
   - sops-nix descriptografa usando a **host key privada** (`/etc/ssh/ssh_host_ed25519_key`)
   - Escreve em `/run/secrets/<name>` (ex: `/run/secrets/vnc-password`)
4. Serviços leem de `/run/secrets/...`

### Exemplo (wayvnc):
```nix
sops.secrets."vnc-password" = {
  sopsFile = "${config.hamra.secrets.path}/vnc.yaml";
  owner = config.hamra.users.userName;
  mode = "0400";
};
# systemd service usa: ExecStart = "... --password-file /run/secrets/vnc-password"
```

---

## Máquinas e Estado Atual

| Máquina | Tem editing key? | Host key no .sops.yaml? | Descriptografa vnc.yaml? | Descriptografa samba.yaml? |
|---------|------------------|-------------------------|--------------------------|----------------------------|
| **samsung** | ❌ (provavelmente) | ✅ `host-samsung` | ✅ | ✅ |
| **acer** | ❌ | ✅ `host-acer` | ✅ | ✅ |
| **vm** | ❌ | ❌ | ❌ | ❌ |
| **Máquina de edição** | ✅ | — | — | — |

> **Importante:** Apenas **uma** máquina deve ter a editing key privada (`~/.config/sops/age/keys.txt`). As outras usam apenas a host key (derivada do SSH) para descriptografar no boot.

---

## Troubleshooting

### "FAILED to decrypt / No master key"
- Você está rodando `sops` numa máquina **sem a editing key** E **sem host key válida no .sops.yaml**
- Solução: rode na máquina de edição, ou adicione a host key da máquina atual no .sops.yaml + `sops updatekeys`

### "identity did not match any recipients"
- O arquivo foi criptografado para recipients que **não incluem** a chave da máquina atual
- Solução: `sops updatekeys` na máquina de edição

### Host novo não descriptografa no boot
- Verifique se a host key pública está no `.sops.yaml` E no `creation_rules` do secret
- Verifique se `sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]` está no módulo
- Rebuild: `sudo nixos-rebuild switch --flake .#host`

### Chave SSH do host mudou (reinstalou SO)
```bash
# 1. Nova host key
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
# 2. Atualize .sops.yaml
# 3. sops updatekeys (na máquina de edição)
# 4. Rebuild no host
```

---

## Comandos Úteis

```bash
# Ver recipients de um arquivo
sops -i secrets/vnc.yaml   # abre editor
sops -d secrets/vnc.yaml   # descriptografa no stdout

# Atualizar recipients (na máquina de edição)
sops updatekeys secrets/vnc.yaml secrets/samba.yaml

# Verificar se consegue descriptografar no host atual
nix develop --command sops -d secrets/vnc.yaml

# Gerar host key age a partir da SSH key
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age

# Gerar editing key (uma vez só)
age-keygen > ~/.config/sops/age/keys.txt
```

---

## Segurança

- **NUNCA** commite chaves privadas (age ou SSH)
- `secrets/*.yaml` são **criptografados** — seguro commitar
- `.sops.yaml` tem apenas **chaves públicas** — seguro commitar
- Editing key privada (`~/.config/sops/age/keys.txt`) **sai do repo** — backup seguro (password manager, pendrive offline, etc.)
- Host keys privadas ficam em `/etc/ssh/` (protegidas pelo SO)