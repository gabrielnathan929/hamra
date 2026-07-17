{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.development.gcc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.development.gcc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GCC.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gcc];
}
