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
    meta = {
      description = "Deploy NixOS configuration for ${host}";
      mainProgram = "hamra-deploy-${host}";
    };
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
    meta = {
      description = "Build NixOS configuration for ${host}";
      mainProgram = "hamra-build-${host}";
    };
  };

  hosts = builtins.attrNames self.nixosConfigurations;

  hamraInit = pkgs.writers.writePython3Bin "hamra-init" {
    flakeIgnore = ["E501" "E265" "W503"];
  } (builtins.readFile ../scripts/hamra-init.py);

  cookiecutter = self.packages.${system}.cookiecutter;

  mkApps = fn: prefix:
    builtins.listToAttrs (map (h: {
        name = "${prefix}-${h}";
        value = fn h;
      })
      hosts);
in {
  ${system} =
    (mkApps mkDeployApp "deploy"
      // mkApps mkBuildApp "build")
    // {
      hamra-init = {
        type = "app";
        program = "${hamraInit}/bin/hamra-init";
        meta = {
          description = "Generate and validate a new Hamra host (CLI engine)";
          mainProgram = "hamra-init";
        };
      };
      cookiecutter = {
        type = "app";
        program = pkgs.lib.getExe cookiecutter;
        meta = {
          description = "CookieCutter — shape a new Hamra machine from a template";
          mainProgram = "cookiecutter";
        };
      };
    };
}
