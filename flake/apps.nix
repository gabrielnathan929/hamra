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

  hamraSetup = pkgs.stdenv.mkDerivation {
    pname = "hamra-setup";
    version = "0.1";
    dontUnpack = true;
    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.gtk4 pkgs.libadwaita pkgs.glib pkgs.gdk-pixbuf];
    pythonEnv = pkgs.python3.withPackages (ps: [ps.pygobject3]);
    typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
      pkgs.gtk4
      pkgs.libadwaita
      pkgs.glib
      pkgs.gdk-pixbuf
      pkgs.gobject-introspection
      pkgs.graphene
      pkgs.pango
      pkgs.harfbuzz
      pkgs.cairo
      pkgs.freetype
      pkgs.fontconfig
      pkgs.wayland
    ];
    schemasPath = pkgs.lib.makeSearchPath "share/gsettings-schemas" [
      pkgs.gtk4
      pkgs.libadwaita
      pkgs.glib
    ];
    installPhase = ''
      mkdir -p $out/bin $out/share/hamra-setup
      cp ${../scripts/hamra-setup.py} $out/share/hamra-setup/hamra-setup.py
      cp ${../scripts/hamra-init.py} $out/share/hamra-setup/hamra-init.py
      makeWrapper $pythonEnv/bin/python3 \
        $out/bin/hamra-setup \
        --set GI_TYPELIB_PATH "$typelibPath" \
        --set GSETTINGS_SCHEMAS_PATH "$schemasPath" \
        --set XDG_DATA_DIRS "${pkgs.gtk4}/share:${pkgs.libadwaita}/share:${pkgs.glib}/share" \
        --set GDK_PIXBUF_MODULE_FILE "${pkgs.gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
        --add-flags "$out/share/hamra-setup/hamra-setup.py"
    '';
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
          description = "Generate and validate a new Hamra host";
          mainProgram = "hamra-init";
        };
      };
      hamra-setup = {
        type = "app";
        program = "${hamraSetup}/bin/hamra-setup";
        meta = {
          description = "Graphical installer for a new Hamra host (GTK4/libadwaita)";
          mainProgram = "hamra-setup";
        };
      };
    };
}
