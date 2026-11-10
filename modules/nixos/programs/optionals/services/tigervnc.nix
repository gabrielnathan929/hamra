{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.tigervnc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.services.tigervnc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable TigerVNC client tools (vncviewer) — a VNC client, not a server. Remote desktop is served by the wayvnc toggle.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tigervnc];
}
