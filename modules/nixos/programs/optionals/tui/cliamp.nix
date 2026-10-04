{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.hamra.programs.optionals.tui.cliamp;
in {
  options.hamra.programs.optionals.tui.cliamp = mkOption {
    type = types.bool;
    default = false;
    description = "Enable cliamp utility.";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.cliamp
  ];
}
