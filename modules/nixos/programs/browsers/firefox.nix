{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.browsers.firefox;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.browsers.firefox = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Firefox.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.firefox];
}
