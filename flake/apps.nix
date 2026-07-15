{
  pkgs,
  system,
  self,
}: let
  mkDeployApp = host: let
    script = pkgs.writeShellScript "hamra-deploy-${host}" ''
      set -euo pipefail

      HOST="${host}"
      FLAKE="''${FLAKE:-${self}}"

      nix flake check "$FLAKE"

      sudo nixos-rebuild switch --flake "$FLAKE#$HOST"

      echo "deploy de #$HOST concluido"
    '';
  in {
    type = "app";
    program = "${script}";
  };

  mkBuildApp = host: let
    script = pkgs.writeShellScript "hamra-build-${host}" ''
      set -euo pipefail

      HOST="${host}"
      FLAKE="''${FLAKE:-${self}}"

      nix build "$FLAKE#nixosConfigurations.$HOST.config.system.build.toplevel" \
        --extra-experimental-features "nix-command flakes"

      echo "build de #$HOST salvo em ./result"
    '';
  in {
    type = "app";
    program = "${script}";
  };
in {
  ${system} = {
    deploy-desktop = mkDeployApp "desktop";
    deploy-vm = mkDeployApp "vm";
    build-desktop = mkBuildApp "desktop";
    build-vm = mkBuildApp "vm";
  };
}
