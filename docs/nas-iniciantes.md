# NAS do Hamra — guia para quem nunca mexeu com isso

Este guia é para QUALQUER pessoa que queira montar o NAS (a "nuvem caseira")
em qualquer PC usando este repositório. Você **não precisa entender de
criptografia nem de NixOS** — o assistente `setup-nas` faz tudo, explicando
cada passo. Quando aparecer um erro, ele diz **o que fazer a seguir**.

> Conceito rápido: o NAS é uma pasta de rede compartilhada entre PCs.
> Este repositório guarda uma senha **criptografada** dela. As chaves
> criptográficas são os "cadeados" que abrem essa senha.

---

## 1. De um só trago (o caminho feliz)

Em um PC com NixOS e este repositório em `/etc/nixos`:

```bash
cd /etc/nixos
nix develop              # prepara as ferramentas (1ª vez demora um pouco)
./scripts/setup-nas.sh   # o assistente guiado
```

O assistente pergunta pouca coisa (nome do PC, GPU, desktop, e a **sua**
senha do NAS) e depois:

1. cria o "host" deste PC no repositório (arquivos de configuração);
2. gera a chave de **edição** dos segredos (se ainda não existir aqui);
3. registra a chave deste PC no `.sops.yaml`;
4. grava a sua senha criptografada em `secrets/samba.yaml`;
5. pergunta se quer **aplicar** no PC (recomenda-se sim) e, se você
   confirmou, reconfigura o sistema — o Samba passa a compartilhar
   as pastas `shared`, `games` e `backups`.

Pronto. Qualquer outro PC pode acessar: mesmo script **naquele PC**.

---

## 2. Primeiros passos em um PC novo (passo a passo detalhado)

### 2.1. Tenha o repositório na máquina

```bash
sudo mkdir -p /etc/nixos
sudo chown $(whoami):users /etc/nixos
git clone <endereço-do-repositório> /etc/nixos
```

> Troque `<endereço-do-repositório>` pelo link "Clone" do GitHub
> (botão verde). Ex.: `https://github.com/seuusuario/hamra.git`.

### 2.2. Entre no ambiente de trabalho

```bash
cd /etc/nixos
nix develop
```

Este comando instala (na primeira vez) as ferramentas: `sops`, `age`,
`ssh-to-age`, `python3`. Ele não altera seu sistema — é só um "banheiro
de ferramentas" temporário.

### 2.3. Rode o assistente

```bash
./scripts/setup-nas.sh
```

O que cada pergunta significa:

| Pergunta | O que é | Dica |
|---|---|---|
| Nome deste PC no repositório | Apelido da máquina nos arquivos do repo | Pode ser o nome do PC, ex.: `notebook`, `servidor`, `desktop` |
| GPU do PC | Placa gráfica | `intel`, `amd`, `nvidia` ou `virtio` (máquinas virtuais) |
| Firmware | Tipo de inicialização | `uefi` (padrão) ou `bios` |
| Desktop | Ambiente gráfico | `hyprland`, `sway`, `niri`, `gnome` ou `plasma` |
| Usuário do sistema | Seu usuário no Linux | O mesmo da instalação (ex.: `gabrielnathan`) |
| Senha do NAS | **Sua** senha do compartilhamento | Mínimo 8 caracteres. É digitada 2× e nunca aparece na tela |

Deixe a resposta sugerida (entre colchetes) apertando apenas **Enter** se
não souber.

### 2.4. Publique no repositório

No final o assistente mostra:

```bash
git add -A && git commit -m "Add NAS setup" && git push
```

Assim o repositório vira "fonte da verdade": **qualquer PC pode recriar**
a mesma configuração só rodando este guia.

---

## 3. Esqueci a senha do NAS (acontece!)

Dentro do repositório:

```bash
nix develop
./scripts/setup-nas.sh --mostrar-senha
```

Ele mostra a senha na tela. Para o comando funcionar, o PC precisa ter
**uma** das duas coisas:

- a chave de edição em `~/.config/sops/age/keys.txt`; ou
- a chave SSH deste PC cadastrada no `.sops.yaml` (em NixOS isso é
  automático, sem nada para fazer).

### Perdi a chave de edição **e** meu PC não está cadastrado

O arquivo `secrets/samba.yaml` não abre (é essa a proteção). Soluções:

- **O melhor caminho:** peça a alguém que tenha o repositório com acesso
  para rodar no PC dele:
  ```bash
  nix develop
  printf 'y\n' | sops updatekeys secrets/samba.yaml   # adiciona seu PC
  ```
  e publique. Daí, no seu PC, o `--mostrar-senha` passa a funcionar.
- **Alternativa drástica:** apagar o segredo e recriar com senha nova:
  ```bash
  rm secrets/samba.yaml && ./scripts/setup-nas.sh --reset-senha
  ```
  A nova senha entra em vigor no próximo `nixos-rebuild switch` de
  qualquer host com o Samba ativo (o script de ativação sincroniza
  automaticamente). OS CLIENTES PRECISAM USAR A NOVA SENHA.

---

## 4. Quero trocar a senha

```bash
nix develop
./scripts/setup-nas.sh --reset-senha
```

Troca, criptografa de novo e sincroniza os PCs cadastrados. Depois
execute em cada host do Samba:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#<host>
```

E atualize os clientes (arquivo `/etc/samba/cred-nas`, se usado).

---

## 5. Só conferir o ambiente, sem alterar nada

```bash
nix develop
./scripts/setup-nas.sh --check
```

Lista o que existe e o que falta. Ótimo para diagnosticar antes de rodar
o assistente.

---

## 6. Usar o NAS de outros PCs (clientes)

### Linux (Arch/qualquer distro)

Crie o arquivo de credenciais (1 vez):

```bash
sudo pacman -S cifs-utils                      # Arch
echo 'username=gabrielnathan' | sudo tee /etc/samba/cred-nas
echo 'password=sua-senha'     | sudo tee -a /etc/samba/cred-nas
sudo chmod 600 /etc/samba/cred-nas
```

Monte (ou coloque essas linhas no `/etc/fstab` para montar
automaticamente):

```fstab
//IP-DO-NAS/shared  /mnt/nas-shared  cifs  credentials=/etc/samba/cred-nas,uid=1000,gid=100,iocharset=utf8,noauto,x-systemd.automount,x-systemd.idle-timeout=60 0 0
//IP-DO-NAS/games   /mnt/nas-games   cifs  credentials=/etc/samba/cred-nas,uid=1000,gid=100,iocharset=utf8,noauto,x-systemd.automount,x-systemd.idle-timeout=60 0 0
//IP-DO-NAS/backups /mnt/nas-backups cifs  credentials=/etc/samba/cred-nas,uid=1000,gid=100,iocharset=utf8,noauto,x-systemd.automount,x-systemd.idle-timeout=60 0 0
```

```bash
sudo mkdir -p /mnt/nas-{shared,games,backups}
sudo mount -a
```

> O IP do NAS aparece com `ip a` no PC que tem o Samba ativado.
> Se quiser IP fixo, reserve no roteador (rede local) ou configure um
> endereço estático.

### Windows

No Explorador de Arquivos, endereço: `\\IP-DO-NAS\shared` \
(Ao pedir usuário, use `gabrielnathan` e a senha do NAS.)

### Mac

Finder → Ir → Conectar ao servidor → `smb://IP-DO-NAS/shared`

---

## 7. Problemas comuns (e o que fazer)

| Erro / situação | O que está acontecendo | Solução |
|---|---|---|
| `Faltam ferramentas: ...` | Você não está no ambiente | Rode `nix develop` e tente de novo |
| `no matching creation rules found` | Um arquivo em local errado foi criptografado | Manualmente raro; rode o assistente de novo — ele grava o rascunho na pasta certa |
| `sops metadata not found` | O sops achou o arquivo "meio criptografado" | Rode novamente; se persistir, `rm secrets/samba.yaml && ./scripts/setup-nas.sh --reset-senha` |
| `Não achei <ip> ... shared` ao montar | Samba fora do ar ou IP errado | `sudo systemctl status samba-smbd.service` no NAS; confira o IP |
| Senha não aceita ao montar | Credencial desatualizada | Repita a seção 6 (ou seção 4 se trocou a senha) |
| Rebuild falha | Alguma validação do NixOS rejeitou a config | Leia o erro; o assistente aponta o comando para refazer |
| Esqueci a senha | — | Seção 3 deste guia |

---

## 8. Segurança — o que pode e o que NÃO pode ir para o GitHub

**Pode (é criptografado):**

- `secrets/samba.yaml` — contém a senha, mas cifrada. Sem as chaves,
  ninguém lê.

**NUNCA committe:**

- `~/.config/sops/age/keys.txt` — é a "senha-mestra" dos segredos.
- `/etc/ssh/ssh_host_ed25519_key` (arquivo privado — o `.pub` é ok).
- Senhas em texto claro, em qualquer arquivo.

---

## 9. A lixeira do NAS (anti-apagão)

Apagar um arquivo/pasta **pelo compartilhamento** (Windows, Mac, Linux) não
apaga de verdade: o Samba move tudo para uma **lixeira** dentro do próprio
compartilhamento, na pasta oculta `.trash` (`/data/shared/.trash`,
`/data/games/.trash`, `/data/backups/.trash`).

- **Como ver:** no Windows habilite "Itens ocultos"; no Linux, `ls -a`
  na pasta montada. As pastas preservam a origem (`keeptree`) e a data.
- **Duplicado:** se você apagar um nome que já está na lixeira, ele guarda
  as **duas versões** (sufixo com a data) — nada se perde por sobrescrever.
- **Recuperar:** é só mover o arquivo de volta para a pasta original.
- **Esvaziar:** apague o que quiser de dentro de `.trash` (ocupa espaço —
  limpe de vez em quando).

Limitações honestas:

- Protege contra apagar **via rede (SMB)** — inclusive o Shift+Delete do
  Windows. Um `rm` direto no servidor **apaga de verdade**: não fique
  rodando `rm` na máquina que tem o NAS.
- Arquivos temporários (`.tmp`, `~$`... do Office) saem **sem** passar pela
  lixeira (para não entulhar).
- A lixeira vive no mesmo disco — é um para-choque contra **acidente**,
  não um backup. Para cópia real, veja a seção sobre backups.