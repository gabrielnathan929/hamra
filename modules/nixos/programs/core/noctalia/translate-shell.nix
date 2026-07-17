{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.noctalia."translate-shell";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.noctalia."translate-shell" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable translate-shell (CLI translator, Noctalia plugin dependency).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.translate-shell];
}
