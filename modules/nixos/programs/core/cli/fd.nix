{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.fd;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.fd = mkOption {
    type = types.bool;
    default = true;
    description = "Enable fd-find.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.fd];
}
