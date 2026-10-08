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

    # 2. (Unnecessary with a secure Electron) Bypass the Electron EOL block
    # nixpkgs.config.permittedInsecurePackages = [
    #   "electron-39.8.10" # IMPORTANT: change to the exact version Nix complains about in your terminal
    # ];

    # 3. Ensures prebuilt binaries + a secure Electron version
    nixpkgs.overlays = [
      (final: prev: {
        bitwarden-desktop = prev.bitwarden-desktop.override {
          # This makes Bitwarden use the prebuilt Electron 43 binary
          electron_43 = final.electron_43-bin;
        };
      })
    ];
  };
}
