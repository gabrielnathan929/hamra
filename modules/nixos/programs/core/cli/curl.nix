{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.curl;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.curl = mkOption {
    type = types.bool;
    default = true;
    description = "Enable curl.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.curl];
}
