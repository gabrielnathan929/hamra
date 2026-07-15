{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.xdg;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.xdg = mkOption {
    type = types.bool;
    default = false;
    description = "Configure XDG user directories and MIME associations.";
  };

  config = mkIf cfg {
    xdg = {
      userDirs.enable = true;
      mime.enable = true;
    };

    home.packages = with pkgs; [
      gvfs
    ];
  };
}
