{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.packaging.gnome-software;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.packaging.gnome-software = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNOME Software with Flatpak support.";
  };

  config = mkIf cfg {
    services.packagekit.enable = true;
    environment.systemPackages = with pkgs; [
      gnome-software
      gnome-software-plugin-flatpak
    ];
  };
}
