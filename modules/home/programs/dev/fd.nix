{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.fd;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.fd = mkOption {
    type = types.bool;
    default = false;
    description = "Enable fd (find replacement).";
  };

  config.home.packages = mkIf cfg [pkgs.fd];
}
