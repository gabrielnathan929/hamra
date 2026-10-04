{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.zoxide;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.zoxide = mkOption {
    type = types.bool;
    default = true;
    description = "Enable zoxide.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.zoxide];
}
