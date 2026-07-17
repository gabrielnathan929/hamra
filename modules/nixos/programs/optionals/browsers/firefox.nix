{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.browsers.firefox;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.browsers.firefox = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Firefox.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.firefox];
}
