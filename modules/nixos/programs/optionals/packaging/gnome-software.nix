{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.packaging."gnome-software";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.packaging."gnome-software" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNOME Software with Flatpak support.";
  };

  config = mkIf cfg {
    services.packagekit.enable = true;
    environment.systemPackages = [
      pkgs."gnome-software"
    ];
  };
}
