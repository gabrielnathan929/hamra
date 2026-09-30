{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.bitwarden;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.bitwarden = mkOption {
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
        bitwarden-desktop = prev.bitwarden-desktop.override {
          # Isso faz o Bitwarden usar o binário pré-compilado do Electron 43
          electron_43 = final.electron_43-bin;
        };
      })
    ];
  };
}
