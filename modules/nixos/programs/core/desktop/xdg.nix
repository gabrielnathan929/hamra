{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.desktop.xdg;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.desktop.xdg = mkOption {
    type = types.bool;
    default = true;
    description = "Configure XDG user directories and MIME associations.";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.gvfs
  ];
}
