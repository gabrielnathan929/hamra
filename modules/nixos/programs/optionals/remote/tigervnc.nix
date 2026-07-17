{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.remote.tigervnc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.remote.tigervnc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable TigerVNC.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tigervnc];
}
