{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.browsers."google-chrome";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.browsers."google-chrome" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Google Chrome.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.google-chrome];
}
