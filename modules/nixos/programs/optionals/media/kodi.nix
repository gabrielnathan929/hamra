{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.kodi;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.media.kodi = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Kodi media center.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.kodi];
  };
}
