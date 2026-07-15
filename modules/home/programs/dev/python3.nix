{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.python3;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.python3 = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Python 3.";
  };

  config.home.packages = mkIf cfg [pkgs.python3];
}
