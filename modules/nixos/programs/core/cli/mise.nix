{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.mise;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.mise = mkOption {
    type = types.bool;
    default = true;
    description = "Enable mise.";
  };

  config.programs.mise = mkIf cfg {
    enable = true;
    enableZshIntegration = true;
  };
}
