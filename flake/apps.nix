{
  pkgs,
  system,
  self,
}: let
  mkDeployApp = host: let
    script = pkgs.writeShellScript "deploy-${host}" ''
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
      mainProgram = "deploy-${host}";
    };
  };

  mkBuildApp = host: let
    script = pkgs.writeShellScript "build-${host}" ''
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
      mainProgram = "build-${host}";
    };
  };

  hosts = builtins.attrNames self.nixosConfigurations;

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
          pkgs.coreutils
          pkgs.findutils
          pkgs.fzf
          pkgs.git
          pkgs.gnused
          pkgs.gum
          pkgs.jq
          pkgs.nix
        ]
      }
    '';

    meta = {
      description = "Generate and validate a new Hamra host (CLI engine)";
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
      cookiecutter = {
        type = "app";
        program = "${cookiecutter}/bin/cookiecutter";
        meta = {
          description = "Generate and validate a new Hamra host (CLI engine)";
          mainProgram = "cookiecutter";
        };
      };
    };
}
