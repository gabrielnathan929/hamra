{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.insomnia;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.insomnia = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Insomnia (API client for testing REST and GraphQL).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.insomnia];
}
