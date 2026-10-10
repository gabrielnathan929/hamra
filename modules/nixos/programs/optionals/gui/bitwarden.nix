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
    description = "Enable Bitwarden Desktop (password manager, prebuilt Electron).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.bitwarden-desktop];

    nixpkgs.overlays = [
      (final: prev: {
        bitwarden-desktop = prev.bitwarden-desktop.override {
          electron_43 = final.electron_43-bin;
        };
      })
    ];
  };
}
