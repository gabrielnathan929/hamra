{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.python3;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.python3 = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Python 3.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.python3];
}
