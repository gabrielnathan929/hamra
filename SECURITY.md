# Política de Segurança

## Reportar uma vulnerabilidade

Use o botão **Report a vulnerability** na aba Security do repositório
(Private Vulnerability Reporting do GitHub) em vez de abrir issue pública.
Descreva o problema, como reproduzir e o impacto. Este é um projeto pessoal
mantido por uma pessoa — sem SLA formal, mas relatórios recebem resposta
assim que possível.

**Escopo do que reportar aqui:**

- Exposição de segredos ou credenciais (commit acidental, configuração que
  vaze valor em claro).
- Configuração insegura dos módulos deste repositório (permissões, polkit,
  sudo, PAM, SSH).
- Escalada de privilégios induzida por algo declarado aqui.

**Fora de escopo:** vulnerabilidades dos programas empacotados (Hyprland,
Noctalia, mise etc.) — reporte no upstream de cada projeto.

## Como este repositório lida com segredos

- Segredos vivem **criptografados** em `secrets/*.yaml` (sops-nix + age).
  Valores em claro nunca entram no repositório.
- As chaves públicas por host ficam no `.sops.yaml`; a chave privada de
  edição vive em `~/.config/sops/age/keys.txt` na máquina do editor — fora
  do repo, fora do Nix Store.
- Cada host decripta com a chave derivada da própria `ssh_host_ed25519_key`
  (registrada via `ssh-to-age`). Um host novo precisa ter a chave registrada
  e o segredo atualizado (`sops updatekeys`) — sem isso ele não abre o
  conteúdo.
- Senhas de serviço (ex.: Samba) são aplicadas na ativação a partir dos
  segredos decriptados — nada passa pelo Nix Store.
- Polkit, keyring, GnuPG e SSH são módulos `core` com toggles explícitos.

## Limitações honestas

- A lixeira dos shares Samba (VFS recycle) é amortecedor contra acidente via
  cliente SMB, não backup. Não protege contra `rm` direto no servidor.
- Os hosts deste repo são das máquinas do autor; hardware e identity ficam em
  `hosts/<nome>/` e o restante é reutilizável por qualquer fork.
