{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.insomnia;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.insomnia = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Insomnia (API client for testing REST and GraphQL).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.insomnia];
}
