{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.security.bitwarden;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.security.bitwarden = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Bitwarden Desktop (password manager).";
  };

  config = mkIf cfg {
    # 1. Instala o Bitwarden
    environment.systemPackages = [pkgs.bitwarden-desktop];

    # 2. (Desnecessário com Electron seguro) Burlar a trava do Electron EOL
    # nixpkgs.config.permittedInsecurePackages = [
    #   "electron-39.8.10" # IMPORTANTE: Altere para a versão exata que o Nix reclamar no seu terminal
    # ];

    # 3. Garante o uso de binários prontos + versão segura do Electron
    nixpkgs.overlays = [
      (final: prev: {
        bitwarden-desktop =
          (prev.bitwarden-desktop.override {
            # Electron seguro (41 não é EOL). Se o app quebrar, use electron_39-bin e descomente o permit acima
            electron_39 = final.electron_41-bin;
          }).overrideAttrs (old: {
            # o nixpkgs trava o build se o major do electron != do package.json (39);
            # com o 41 seguro precisamos pular essa checagem
            preBuild = ''
              echo "export const compilerCommand = ['dart-sass'];" > node_modules/sass-embedded/dist/lib/src/compiler-path.js
              patchShebangs apps/desktop/node_modules
              pushd apps/desktop/desktop_native/napi
              npm run build -- --release
              popd
              pushd apps/desktop/desktop_native/proxy
              cargo build --bin desktop_proxy --release -j $NIX_BUILD_CORES --offline
              popd
            '';
          });
      })
    ];
  };
}
