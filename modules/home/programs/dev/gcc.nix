{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.gcc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.gcc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GCC compiler.";
  };

  config.home.packages = mkIf cfg [pkgs.gcc];
}
