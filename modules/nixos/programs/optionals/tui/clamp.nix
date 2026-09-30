{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.hamra.programs.optionals.tui.clamp;
in {
  options.hamra.programs.optionals.tui.clamp = mkOption {
    type = types.bool;
    default = false;
    description = "Enable clamp utility.";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.cliamp
  ];
}
