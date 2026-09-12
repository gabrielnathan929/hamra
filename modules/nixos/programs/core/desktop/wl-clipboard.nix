{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.desktop."wl-clipboard";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.desktop."wl-clipboard" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable wl-clipboard.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.wl-clipboard];
}
