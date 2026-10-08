{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts."setup-nas";
  inherit (lib) mkOption mkIf types;

  setup-nas = pkgs.writeShellScriptBin "setup-nas" ''
    set -euo pipefail
    script=""
    if [[ -n ''${HAMRA_REPO:-} && -f "$HAMRA_REPO/scripts/setup-nas.sh" ]]; then
      script="$HAMRA_REPO/scripts/setup-nas.sh"
    elif [[ -f /etc/nixos/scripts/setup-nas.sh ]]; then
      script=/etc/nixos/scripts/setup-nas.sh
    fi
    if [[ -z $script ]]; then
      echo "setup-nas: não encontrei o repositório (procurei em \$HAMRA_REPO e /etc/nixos)." >&2
      echo "Aponte HAMRA_REPO para o checkout ou crie o symlink: sudo ln -s <checkout> /etc/nixos" >&2
      exit 1
    fi
    exec bash "$script" "$@"
  '';
in {
  options.hamra.programs.core.scripts."setup-nas" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable setup-nas wizard (Samba NAS + sops secrets).";
  };

  config.environment.systemPackages = mkIf cfg [setup-nas];
}
