{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.curl;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.curl = mkOption {
    type = types.bool;
    default = false;
    description = "Enable curl.";
  };

  config.home.packages = mkIf cfg [pkgs.curl];
}
