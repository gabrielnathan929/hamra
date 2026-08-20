#!/usr/bin/env bash
#
# setup-nas — Assistente para instalar/recriar o NAS (Samba + segredos) em QUALQUER PC
# usando este repositório Hamra.
#
# O que ele faz, em ordem:
#   1. Confere se as ferramentas necessárias existem.
#   2. Garante que este PC tem um "host" registrado no repositório.
#   3. Gera a chave de edição dos segredos (se ainda não existir).
#   4. Registra as chaves deste PC no arquivo ".sops.yaml".
#   5. Cria/renova a senha do NAS (ela fica criptografada em secrets/samba.yaml).
#   6. Aplica a configuração no PC (opcional).
#
# Modos:
#   ./scripts/setup-nas.sh              assistente completo (recomendado)
#   ./scripts/setup-nas.sh --check      só confere o ambiente (não muda nada)
#   ./scripts/setup-nas.sh --mostrar-senha   esqueceu a senha do NAS
#   ./scripts/setup-nas.sh --reset-senha     forçar criação de uma senha nova
#   ./scripts/setup-nas.sh --ajuda      esta ajuda
#
# Dica: rode `nix develop` primeiro — o ambiente já traz sops, age e ssh-to-age.
set -uo pipefail

# ---------------------------------------------------------------------------
# Cores (apenas se estiver num terminal)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  _B=$'\033[1m'; _D=$'\033[2m'; _R=$'\033[31m'; _G=$'\033[32m'
  _Y=$'\033[33m'; _C=$'\033[36m'; _N=$'\033[0m'
else
  _B=""; _D=""; _R=""; _G=""; _Y=""; _C=""; _N=""
fi

info()  { printf "%s• %s%s\n" "$_C" "$*" "$_N"; }
title() {
  printf "\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$_B" "$_N"
  printf "%s  %s%s\n" "$_B" "$*" "$_N"
  printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$_B" "$_N"
}
ok()    { printf "%s✔ %s%s\n" "$_G" "$*" "$_N"; }
warn()  { printf "%s⚠ %s%s\n" "$_Y" "$*" "$_N"; }
fail()  { printf "%s✖ %s%s\n" "$_R" "$*" "$_N"; }

die() {
  local help_msg="${_HELP:-}"
  fail "$1"
  if [[ -n $help_msg ]]; then
    printf "\n%sCOMO RESOLVER:%s\n" "$_B" "$_N"
    printf "%s\n" "$help_msg"
  fi
  printf "\nSe ainda ficou preso, leia docs/nas-iniciantes.md\n"
  printf "ou procure a seção \"NAS / Samba\" no AGENTS.md.\n"
  exit "${2:-1}"
}

yesno() {
  local q="${1:-Continuar?}" d="${2:-s}" r
  printf "%s? [%s/n] " "$q" "$d"
  read -r r
  case "${r:-$d}" in
    [nN]|[nN][aã][oO]) return 1 ;;
    *) return 0 ;;
  esac
}

ask() {
  local q="$1" d="${2:-}"
  printf "  %s" "$q"
  [[ -n $d ]] && printf " [%s]" "$d"
  printf ": "
  read -r REPLY
  [[ -z ${REPLY:-} && -n $d ]] && REPLY="$d"
}

# ---------------------------------------------------------------------------
# Ferramentas disponíveis
# ---------------------------------------------------------------------------
declare -A TOOLS

collect_tools() {
  local t
  for t in nix sops age age-keygen ssh-to-age python3 git nixos-rebuild sudo; do
    if command -v "$t" >/dev/null 2>&1; then TOOLS[$t]=1; else TOOLS[$t]=0; fi
  done
}

require_tools() {
  local missing=() t
  for t in nix sops age age-keygen ssh-to-age python3 git; do
    (( TOOLS[$t] )) || missing+=("$t")
  done
  if ((${#missing[@]})); then
    _HELP="Rode o comando:  nix develop
(o 'devShell' deste repositório já instala tudo que falta.)
Depois execute de novo:  ./scripts/setup-nas.sh"
    die "Faltam ferramentas: ${missing[*]}"
  fi
}

# Relatório (modo --check, não altera nada)
check_env() {
  title "Verificação do ambiente --check"
  printf "  Repositório : %s\n" "$REPO"
  printf "  Diretório   : %s\n" "$(pwd)"
  printf "\n  %-18s %s\n" "Ferramenta" "Status"
  for t in nix sops age age-keygen ssh-to-age python3 git nixos-rebuild sudo; do
    if (( TOOLS[$t] )); then
      printf "  %-18s %s\n" "$t" "ok ✔"
    else
      printf "  %-18s %s\n" "$t" "ausente ✖"
    fi
  done
  printf "\n  %sDica:%s rode  nix develop  para ter tudo que falta.\n" "$_B" "$_N"
}

# ---------------------------------------------------------------------------
# Descobrir onde está o repositório
# ---------------------------------------------------------------------------
REPO=""

detect_repo() {
  local dir=""
  if [[ -n ${HAMRA_REPO:-} ]]; then
    dir="$HAMRA_REPO"
  elif [[ ${BASH_SOURCE[0]} == */scripts/setup-nas.sh ]]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  else
    dir="/etc/nixos"
  fi

  if [[ ! -f "$dir/scripts/setup-nas.sh" ]]; then
    _HELP="Clone o repositório neste PC primeiro. Ex.:
  sudo mkdir -p /etc/nixos
  sudo chown \$(whoami):users /etc/nixos
  git clone <url-do-repo> /etc/nixos
Depois rode:  cd /etc/nixos && nix develop && ./scripts/setup-nas.sh"
    die "Não encontrei o repositório Hamra em: $dir"
  fi
  REPO="$(cd "$dir" && pwd)"
  cd "$REPO" || die "Não consegui entrar em $REPO"
}

# ---------------------------------------------------------------------------
# Chave de edição (quem autoriza LER/EDITAR os segredos)
# ---------------------------------------------------------------------------
AGE_KEYS="$HOME/.config/sops/age/keys.txt"
EDIT_PUB=""

ensure_edit_key() {
  title "Chave de edição dos segredos"
  info "A senha do NAS fica guardada CRIPTOGRADADA em secrets/samba.yaml."
  info "Para poder ler/editar esse arquivo, o PC precisa de uma chave de"
  info "edição guardada em: $AGE_KEYS"

  if [[ ! -f $AGE_KEYS ]]; then
    if ! yesno "Chave não existe aqui. Quer GERAR uma agora"; then
      _HELP="Sem a chave de edição não é possível ler nem redefinir a senha do NAS
por este PC. Se você só quer USAR o NAS (ler/gravar arquivos), não precisa.
Se quer ADMINISTRAR, copie a chave de outro PC (seu ~/.config/sops/age/keys.txt)."
      die "Nenhuma chave de edição disponível."
    fi
    mkdir -p "$(dirname "$AGE_KEYS")" || die "Não consegui criar ~/.config/sops"
    chmod 700 "$(dirname "$AGE_KEYS")"
    age-keygen -o "$AGE_KEYS" || die "Falha ao gerar a chave de edição."
    chmod 600 "$AGE_KEYS"
    ok "Chave criada em $AGE_KEYS"
    warn "IMPORTANTE: guarde uma cópia num lugar seguro (gerenciador de senhas)."
    warn "Se perdê-la, você não conseguirá mais ler/editar a senha do NAS."
  fi

  EDIT_PUB=$(age-keygen -y "$AGE_KEYS") || die "Não consegui ler a chave de edição (age-keygen)."
  ok "Chave de edição OK (pública: $EDIT_PUB)"
}

# ---------------------------------------------------------------------------
# Chave do host (derivada da chave SSH deste PC — decripta os segredos no boot)
# ---------------------------------------------------------------------------
HOST_PUB=""

host_pubkey() {
  local ssh_pub=/etc/ssh/ssh_host_ed25519_key.pub
  [[ -f $ssh_pub ]] || {
    _HELP="Este PC não tem chave SSH de host em $ssh_pub.
Em NixOS ela é criada automaticamente. Se estiver rodando em outro sistema
(Ex.: Arch), a instalação deste repositório é pré-requisito."
    die "Não encontrei $ssh_pub"
  }
  if command -v ssh-to-age >/dev/null 2>&1; then
    HOST_PUB=$(cat "$ssh_pub" | ssh-to-age)
  else
    HOST_PUB=$(cat "$ssh_pub" | nix run nixpkgs#ssh-to-age 2>/dev/null)
  fi
  [[ $HOST_PUB =~ ^age1[0-9a-z]{50,}$ ]] || die "Falha ao converter a chave SSH em chave age."
  ok "Chave deste PC: $HOST_PUB"
}

# ---------------------------------------------------------------------------
# Registrar chaves no .sops.yaml (inserção segura, preserva comentários)
# ---------------------------------------------------------------------------
patch_sops_yaml() {
  python3 - "$REPO/.sops.yaml" "$1" <<'PYEOF'
import json, os, re, sys

path, data = sys.argv[1], json.loads(sys.argv[2])

anchor_re = re.compile(r'^\s*-\s*&([A-Za-z0-9_-]+)\s+(age1[0-9a-z]+)\s*$')
ref_re    = re.compile(r'^\s*-\s*\*([A-Za-z0-9_-]+)\s*$')

def skeleton():
    return ["keys:", "", "creation_rules:",
            "  - path_regex: secrets/.+\\.yaml$",
            "    key_groups:", "      - age:"]

lines = open(path).read().splitlines() if os.path.exists(path) else skeleton()
if not lines:
    lines = skeleton()

def scan():
    keys_idx = rules_idx = age_idx = last_anchor = last_ref = None
    anchors, by_key = {}, {}
    for i, ln in enumerate(lines):
        if re.match(r'^keys:\s*$', ln):          keys_idx = i
        if re.match(r'^creation_rules:\s*$', ln): rules_idx = i
        m = anchor_re.match(ln)
        if m and keys_idx is not None and (rules_idx is None or i < rules_idx):
            anchors[m.group(1)] = m.group(2)
            by_key[m.group(2)] = m.group(1)
            last_anchor = i
        m = ref_re.match(ln)
        if m and rules_idx is not None and i > rules_idx:
            last_ref = i
        if rules_idx is not None and i > rules_idx and re.match(r'^\s*- age:\s*$', ln):
            age_idx = i
    return keys_idx, rules_idx, age_idx, last_anchor, last_ref, anchors, by_key

added = []
for d in data:
    name, key = d["name"], d["key"]
    keys_idx, rules_idx, age_idx, last_anchor, last_ref, anchors, by_key = scan()

    if key in by_key:
        existing = by_key[key]
        if not any(ref_re.match(l) and ref_re.match(l).group(1) == existing for l in lines):
            at = (last_ref + 1) if last_ref is not None else (age_idx + 1 if age_idx is not None else rules_idx + 1)
            lines.insert(at, "          - *%s" % existing)
            added.append("*%s" % existing)
        continue

    aname, n = name, 2
    while aname in anchors:
        aname = "%s%d" % (name, n); n += 1
    anchor_line = "  - &%s %s" % (aname, key)
    if last_anchor is not None:
        lines.insert(last_anchor + 1, anchor_line)
    else:
        if keys_idx is None:
            lines.insert(0, "keys:")
            keys_idx = 0
        lines.insert(keys_idx + 1, anchor_line)
    added.append("&%s" % aname)

    keys_idx, rules_idx, age_idx, last_anchor, last_ref, anchors, by_key = scan()
    if age_idx is None:
        if rules_idx is None:
            lines.append("creation_rules:")
            rules_idx = len(lines) - 1
        lines.insert(rules_idx + 1, "  - path_regex: secrets/.+\\.yaml$")
        lines.insert(rules_idx + 2, "    key_groups:")
        lines.insert(rules_idx + 3, "      - age:")
        age_idx = rules_idx + 3
        last_ref = None
    at = (last_ref + 1) if last_ref is not None else (age_idx + 1)
    lines.insert(at, "          - *%s" % aname)
    added.append("*%s" % aname)

open(path, "w").write("\n".join(lines) + "\n")
print("Adicionados: %s" % ", ".join(added) if added else "tudo já estava registrado")
PYEOF
}

# ---------------------------------------------------------------------------
# Garantir que o host esteja registrado no repositório
# ---------------------------------------------------------------------------
HOST_NAME=""
HOST_DIR=""
HOST_USER=""
HOST_EXISTS=0

ask_host() {
  title "Seu PC no repositório Hamra"
  local cur name gpu firmware desktop user

  cur="$(hostname 2>/dev/null || echo meu-pc)"
  ask "Nome deste PC dentro do repositório" "$cur"
  name="$REPLY"
  [[ $name =~ ^[a-zA-Z0-9-]+$ ]] || die "Nome inválido (use apenas letras, números e hífen)."

  HOST_NAME="$name"
  HOST_DIR="$REPO/hosts/$HOST_NAME"

  if [[ -f "$HOST_DIR/configuration.nix" ]]; then
    HOST_EXISTS=1
    ok "já existe um host \"$HOST_NAME\" em hosts/$HOST_NAME — vou reaproveitá-lo."
  else
    HOST_EXISTS=0
    info "Este PC ainda não está no repositório. Vou criar a estrutura dele."
    info "Responda algumas perguntas para montar o arquivo de configuração."

    ask "GPU do PC (intel | amd | nvidia | virtio)" "intel"
    case "$REPLY" in
      intel|amd|nvidia|virtio) gpu="$REPLY" ;;
      *) die "GPU \"$REPLY\" inválida. Use: intel, amd, nvidia ou virtio."
    esac

    ask "Firmware (uefi | bios)" "uefi"
    case "$REPLY" in
      uefi|bios) firmware="$REPLY" ;;
      *) die "Firmware \"$REPLY\" inválido. Use: uefi ou bios."
    esac

    ask "Desktop (hyprland | sway | niri | gnome | plasma)" "hyprland"
    case "$REPLY" in
      hyprland|sway|niri|gnome|plasma) desktop="$REPLY" ;;
      *) die "Desktop \"$REPLY\" inválido. Use: hyprland, sway, niri, gnome ou plasma."
    esac

    info "O Samba entrará ATIVADO nesse host (ele é o NAS)."
    HOST_GPU="$gpu"; HOST_FIRMWARE="$firmware"; HOST_DESKTOP="$desktop"
  fi

  ask "Seu usuário do sistema dentro do NixOS" "${USER:-gabrielnathan}"
  user="$REPLY"
  [[ $user =~ ^[a-z][a-z0-9]*$ ]] || die "Nome de usuário inválido (letras minúsculas e números)."
  HOST_USER="$user"
}

create_host() {
  mkdir -p "$HOST_DIR" || die "Não consegui criar hosts/$HOST_NAME"

  info "Gerando hardware-configuration.nix (detecta CPU, placa, discos...)..."
  if (( EUID != 0 )) && (( TOOLS[sudo] )); then
    # O redirect é do shell (arquivo fica do usuário); só a detecção é root.
    # shellcheck disable=SC2024
    sudo -p "Senha do sudo para detectar o hardware: " \
      nixos-generate-config --show-hardware-config > "$HOST_DIR/hardware-configuration.nix" \
      || die "Falha ao gerar o hardware-configuration.nix (sudo)."
  else
    nixos-generate-config --show-hardware-config > "$HOST_DIR/hardware-configuration.nix" \
      || die "Falha ao gerar o hardware-configuration.nix."
  fi
  ok "hardware-configuration.nix criado."

  local cfg="$HOST_DIR/configuration.nix"
  cat > "$cfg" <<'TEMPLATE'
{
  config,
  pkgs,
  lib,
  self,
  inputs,
  ...
}: let
  hamraLib = import "${self.outPath}/modules/lib" {inherit lib;};
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "__NAME__";

    users.userName = "__USER__";

    hardware = {
      gpu = "__GPU__";
      firmware = "__FIRMWARE__";
    };

    desktop.default = "__DESKTOP__";

    env = {
      editor = pkgs.neovim;
      browser = pkgs.helium;
      terminal = pkgs.foot;
      filemanager = pkgs.nautilus;
    };

    packages.extra = [];

    mobile.android = false;

    programs.optionals = {
      virtualisation = {
        boxes = false;
        virt-manager = false;
      };

      packaging = {
        flatpak = false;
        gnome-software = false;
      };

      productivity = {
        obsidian = false;
        office = false;
        drawio = false;
      };

      audio = {
        spotify = false;
        spicetify = false;
      };

      remote.remmina = false;

      utility = {
        appimage = false;
        localsend = false;
        obs = false;
      };

      services = {
        wayvnc = false;
        samba = true;
      };

      games = {
        steam = false;
        pcsx2 = false;
        heroic = false;
        lutris = false;
        hydralauncher = false;
      };

      media = {
        kodi = false;
        nautilus = false;
        qbittorrent = false;
      };

      communication.discord = false;

      security = {
        bitwarden = true;
        "ente-auth" = true;
      };

      ides = {
        vscode = true;
        intellij = false;
        pycharm = false;
        android-studio = false;
        dbeaver = false;
        netbeans = false;
        bruno = false;
        mongodb-compass = false;
        postman = false;
        insomnia = false;
        camunda-modeler = false;
        brmodelo = false;
      };

      development = {
        docker = false;
        go = false;
        jdk = false;
        "docker-compose" = false;
        gcc = false;
        gnumake = false;
        lazydocker = false;
        lazygit = false;
        nodejs = false;
        python3 = false;
        ripgrep = false;
      };
    };

    programs.core.development = {
      git = true;
      opencode = true;
    };
  };

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";

  home-manager = {
    extraSpecialArgs = {
      inherit inputs hamraLib;
      wallpaperPath = config.hamra.theme.wallpaper;
      themesDir = ../../modules/nixos/core/theme/themes;
      keyboard = config.hamra.keyboard;
      desktop = config.hamra.desktop.default;
      displays = config.hamra.displays;
      wayvnc = config.hamra.programs.optionals.services.wayvnc;
      env = config.hamra.env;
    };
    users.${config.hamra.users.userName} = {
      home.stateVersion = "26.05";
      imports = [../../modules/home];

      hamra.home.programs = {
        editors.neovim = true;
      };
    };
  };
}
TEMPLATE

  sed -i \
    -e "s/__NAME__/$HOST_NAME/g" \
    -e "s/__USER__/$HOST_USER/g" \
    -e "s/__GPU__/$HOST_GPU/g" \
    -e "s/__FIRMWARE__/$HOST_FIRMWARE/g" \
    -e "s/__DESKTOP__/$HOST_DESKTOP/g" \
    "$cfg"

  python3 - "$REPO/flake/hosts.nix" "$HOST_NAME" <<'PYEOF'
import re, sys
path, name = sys.argv[1], sys.argv[2]
text = open(path).read()
if re.search(r'mkHost\s+"%s"' % name, text):
    print("host %s já estava em flake/hosts.nix" % name)
    sys.exit(0)
lines = text.splitlines()
if not lines or lines[-1].strip() != "}":
    print("AVISO: flake/hosts.nix terminou de forma inesperada — adicione manualmente:")
    print("  %s = mkHost \"%s\";" % (name, name))
    sys.exit(0)
lines.insert(len(lines) - 1, "  %s = mkHost \"%s\";" % (name, name))
open(path, "w").write("\n".join(lines) + "\n")
print("host %s registrado em flake/hosts.nix" % name)
PYEOF

  ok "host \"$HOST_NAME\" criado. Arquivos:"
  printf "    %s\n" "$HOST_DIR/configuration.nix" "$HOST_DIR/hardware-configuration.nix"
}

ensure_samba_enabled() {
  local cfg="$HOST_DIR/configuration.nix"
  if grep -qE 'samba[[:space:]]*=[[:space:]]*true' "$cfg"; then
    ok "Samba já está ativado no host \"$HOST_NAME\"."
    return 0
  fi
  if grep -q 'samba' "$cfg"; then
    sed -i '0,/samba[[:space:]]*=[[:space:]]*false/s//samba = true/' "$cfg"
    ok "Samba ativado no host \"$HOST_NAME\"."
    return 0
  fi
  warn "Não achei a linha 'samba' no arquivo do host."
  warn "Adicione manualmente dentro de hamra.programs.optionals.services:"
  printf "      services = {\n        wayvnc = false;\n        samba = true;\n      };\n"
}

# ---------------------------------------------------------------------------
# Senha do NAS (criar / manter / trocar)
# ---------------------------------------------------------------------------
NAS_PASSWORD=""

read_password() {
  local p1 p2
  while :; do
    printf "  Digite a senha do NAS (não aparece na tela): "
    read -rs p1; printf "\n"
    if (( ${#p1} < 8 )); then
      warn "A senha precisa ter pelo menos 8 caracteres."; continue
    fi
    printf "  Confirme a senha: "
    read -rs p2; printf "\n"
    if [[ $p1 != "$p2" ]]; then
      warn "As senhas não conferem. Tente de novo."; continue
    fi
    break
  done
  NAS_PASSWORD="$p1"
  p1=""; p2=""
}

write_secret() {
  # O sops escolhe a regra de criptografia pelo CAMINHO do arquivo de entrada.
  # Por isso o plaintext temporário fica em secrets/ (casando com a
  # creation_rules "secrets/.+\.yaml$") e é apagado logo em seguida.
  local tmpf="$REPO/secrets/.tmp-samba.yaml"
  [[ -w secrets ]] || {
    _HELP="A pasta secrets/ não está gravável. Confira o dono da pasta:
  ls -ld secrets
Se preciso:  sudo chown -R \$(whoami):users secrets"
    die "Não consigo escrever em secrets/."
  }
  rm -f "$tmpf"
  printf 'samba-password: %s\n' "$NAS_PASSWORD" > "$tmpf"
  chmod 600 "$tmpf"

  if ! sops --encrypt --input-type yaml --output-type yaml \
      --output secrets/samba.yaml "$tmpf"; then
    rm -f "$tmpf"
    _HELP="O sops usa o arquivo .sops.yaml (criado no passo anterior) para escolher
para quem criptografa. Verifique se .sops.yaml tem a seção creation_rules."
    die "Não consegui criptografar a senha."
  fi
  rm -f "$tmpf"

  if ! sops --decrypt secrets/samba.yaml > /dev/null 2>&1; then
    _HELP="A senha foi criptografada, mas não consegui relê-la agora.
Faça:  nix develop && ./scripts/setup-nas.sh"
    die "Falha ao verificar o arquivo criptografado."
  fi
  ok "senha criptografada com segurança em secrets/samba.yaml"
}

handle_password() {
  title "Senha do NAS"
  local secret_file="secrets/samba.yaml"

  if [[ -f $secret_file && ${FORCE_RESET:-0} == 0 ]]; then
    info "Já existe uma senha criptografada em secrets/samba.yaml."
    if yesno "Manter essa senha atual"; then
      ok "Senha atual mantida."
      return 0
    fi
  fi

  if [[ -f $secret_file ]]; then
    info "A senha antiga será SUBSTITUÍDA. Isso muda o acesso do NAS"
    info "a partir da PRÓXIMA vez que este host for reaplicado no NixOS."
    info "Lembre de atualizar o credencial nos clientes "
    info "(ex.: o arquivo cred-nas usado no /etc/fstab de outros PCs)."
  fi

  read_password
  write_secret

  if [[ -f $secret_file ]]; then
    info "Sincronizando destinatários (para todos os PCs cadastrados"
    info "conseguirem decriptar no boot)..."
    printf 'y\n' | sops updatekeys secrets/samba.yaml >/dev/null \
      || warn "updatekeys falhou — as outras máquinas podem não conseguir aplicar."
    ok "Destinatários sincronizados."
  fi
}

# ---------------------------------------------------------------------------
# Aplicar no PC (opcional)
# ---------------------------------------------------------------------------
deploy() {
  title "Aplicar no PC (nixos-rebuild)"
  if [[ ${TOOLS[nixos-rebuild]} == 0 ]]; then
    warn "Este PC não tem nixos-rebuild (só existe em NixOS)."
    warn "Esta máquina pode ser SÓ UM CLIENTE do NAS (lê/grava os arquivos)."
    return 0
  fi
  if ! yesno "Aplicar a configuração neste PC agora (recomendado)"; then
    info "Você pode aplicar depois com:"
    printf "  sudo nixos-rebuild switch --flake %s#%s\n" "$REPO" "$HOST_NAME"
    return 0
  fi

  if (( EUID != 0 )) && (( TOOLS[sudo] )); then
    if ! sudo -p "Senha do sudo para aplicar a configuração: " -v; then
      _HELP="Não consegui validar a senha do sudo. Rode você mesmo como root:
  sudo nixos-rebuild switch --flake $REPO#$HOST_NAME"
      die "Sudo indisponível."
    fi
    sudo nixos-rebuild switch --flake "$REPO#$HOST_NAME"
    local rc=$?
  else
    nixos-rebuild switch --flake "$REPO#$HOST_NAME"
    local rc=$?
  fi

  if (( rc != 0 )); then
    _HELP="O rebuild falhou. Leia o erro acima. Causas comuns:
  • hardware-configuration.nix com UUID/dispositivo errado (não altere UUIDs).
  • senha do NAS muito curta para o servidor aceitar.
Após corrigir, rode de novo: sudo nixos-rebuild switch --flake $REPO#$HOST_NAME"
    die "Falha ao aplicar a configuração."
  fi
  ok "Configuração aplicada! O Samba já está (ou ficará ativo no reboot)."
}

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
summary() {
  title "Resumo — tudo pronto"
  if [[ -n ${NAS_PASSWORD:-} ]]; then
    info "Senha do NAS deste repositório (sua, criada agora):"
    printf "\n    %s%s%s\n\n" "$_B" "$NAS_PASSWORD" "$_N"
  fi

  printf "  %sUso do NAS:%s\n" "$_B" "$_N"
  printf "    - Linux (montar):  veja docs/nas-iniciantes.md (seção Cliente Linux)\n"
  printf "    - Windows:  acesse \\\\\\\\<ip-do-host>\\\\shared no Explorador de Arquivos\n"
  printf "    - Mac:      Conectar ao servidor -> smb://<ip-do-host>/shared\n"
  printf "  %sGerenciar:%s\n" "$_B" "$_N"
  printf "    - Ver a senha de novo:   ./scripts/setup-nas.sh --mostrar-senha\n"
  printf "    - Trocar a senha:        ./scripts/setup-nas.sh --reset-senha\n"
  printf "    - Adicionar outro PC:    rode este script de novo NAQUELE PC\n"
  printf "  %sPublicar no repositório:%s\n" "$_B" "$_N"
  printf "    git add -A && git commit -m \"Add NAS setup\" && git push\n"
  NAS_PASSWORD=""
}

# ---------------------------------------------------------------------------
# Senha esquecida
# ---------------------------------------------------------------------------
show_password() {
  detect_repo
  cd "$REPO" || die "Não consegui entrar em $REPO"
  if [[ ! -f secrets/samba.yaml ]]; then
    _HELP="Ainda não existe uma senha salva. Rode ./scripts/setup-nas.sh"
    die "Nenhum secret criado ainda."
  fi
  title "Senha do NAS"
  info "Um momento... (precisa da chave de edição OU da chave SSH de um host"
  info "cadastrado neste PC — em NixOS isso é automático)."
  if ! out=$(sops --decrypt secrets/samba.yaml 2>&1); then
    _HELP="Não consegui decriptar. O arquivo só abre com:
  1) a chave de edição em ~/.config/sops/age/keys.txt; OU
  2) num PC NixOS que tenha a chave SSH cadastrada no .sops.yaml.
Se você não tem nenhuma delas, peça a um colega com acesso para adicionar
este PC e rodar:  printf 'y\\n' | sops updatekeys secrets/samba.yaml"
    die "Falha ao decriptar o secret."
  fi
  printf "\n    %s%s%s\n\n" "$_B" "$out" "$_N"
}

# ---------------------------------------------------------------------------
# Ajuda
# ---------------------------------------------------------------------------
ajuda() {
  title "setup-nas — ajuda"
  sed -n '2,28p' "$0"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
collect_tools
FORCE_RESET=0

case "${1:-}" in
  -h|--ajuda|help) ajuda; exit 0 ;;
  --check) detect_repo; check_env; exit 0 ;;
  --mostrar-senha) show_password; exit 0 ;;
  --reset-senha) FORCE_RESET=1 ;;
esac

require_tools
detect_repo

title "Bem-vindo ao setup do NAS"
info "Este assistente prepara este PC para ser um NAS (Samba) usando este"
info "repositório Hamra. Ele explica cada passo e mostra o que fazer se"
info "algo der errado."
info ""
if ! yesno "Vamos começar"; then echo "Até logo!"; exit 0; fi

ask_host
if (( HOST_EXISTS == 0 )); then
  create_host
else
  ensure_samba_enabled
fi

ensure_edit_key
host_pubkey

title "Registro de chaves no .sops.yaml"
info "Adicionando a chave de edição e a chave deste PC no arquivo .sops.yaml..."
if out=$(patch_sops_yaml "[{\"name\":\"user\",\"key\":\"$EDIT_PUB\"},{\"name\":\"host-$HOST_NAME\",\"key\":\"$HOST_PUB\"}]"); then
  ok ":: $out"
else
  _HELP="Ocorreu um erro ao editar .sops.yaml. Veja o modelo comentado
em docs/nas-iniciantes.md e ajuste manualmente se precisar."
  die "Não consegui alterar o .sops.yaml."
fi

handle_password
deploy
summary