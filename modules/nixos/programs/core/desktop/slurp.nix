{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.desktop.slurp;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.desktop.slurp = mkOption {
    type = types.bool;
    default = true;
    description = "Enable slurp region selector.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.slurp];
}
