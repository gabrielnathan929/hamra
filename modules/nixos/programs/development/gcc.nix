{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.gcc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.gcc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GCC.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gcc];
}
