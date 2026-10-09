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

  hamraInit = pkgs.stdenv.mkDerivation {
    pname = "hamra-init";
    version = "0.1.0";
    dontUnpack = true;

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${../scripts/hamra-init.sh} $out/bin/hamra-init \
        --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.findutils
          pkgs.git
          pkgs.gnused
          pkgs.jq
          pkgs.nix
        ]
      }
    '';

    meta = {
      description = "Generate and validate a new Hamra host (CLI engine)";
      mainProgram = "hamra-init";
    };
  };

  cookiecutter = pkgs.stdenv.mkDerivation {
    pname = "cookiecutter";
    version = "0.1.0";
    dontUnpack = true;

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${../scripts/cookiecutter.sh} $out/bin/cookiecutter \
        --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.fzf
          pkgs.git
          pkgs.gum
          pkgs.jq
          pkgs.nix
        ]
      }
    '';

    meta = {
      description = "CookieCutter — shape a new Hamra machine from a template";
      mainProgram = "cookiecutter";
    };
  };

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
