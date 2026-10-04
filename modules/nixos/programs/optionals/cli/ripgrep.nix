{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.ripgrep;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.ripgrep = mkOption {
    type = types.bool;
    default = false;
    description = "Enable ripgrep.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.ripgrep];
}
