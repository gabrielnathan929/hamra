{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.inetutils;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.inetutils = mkOption {
    type = types.bool;
    default = false;
    description = "Enable inetutils (telnet, ftp).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.inetutils];
}
