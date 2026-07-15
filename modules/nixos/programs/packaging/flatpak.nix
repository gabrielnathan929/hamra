{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.packaging.flatpak;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.packaging.flatpak = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Flatpak (universal package manager) support.";
  };

  config = mkIf cfg {
    services.flatpak.enable = true;
    services.packagekit.enable = true;
    environment.systemPackages = with pkgs; [
      gnome-software
    ];
  };
}
