{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.strace;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.strace = mkOption {
    type = types.bool;
    default = false;
    description = "Enable strace.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.strace];
}
