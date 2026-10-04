{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.gcc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.gcc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GCC.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gcc];
}
