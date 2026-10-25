{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.umu;
  userName = config.hamra.users.userName;
  userHome = config.users.users.${userName}.home;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.umu = mkOption {
    type = types.bool;
    default = false;
    description = "Enable umu-launcher (Proton runner outside Steam for Windows installers and games, with a Proton-GE build from the nix store linked into compatibilitytools.d).";
  };

  config = {
    environment.systemPackages = mkIf cfg (with pkgs; [umu-launcher]);

    systemd.tmpfiles.rules = mkIf cfg [
      "d ${userHome}/.local/share/Steam/compatibilitytools.d 0755 ${userName} users - -"
      "L+ ${userHome}/.local/share/Steam/compatibilitytools.d/${pkgs.proton-ge-bin.version} - - - - ${pkgs.proton-ge-bin}"
    ];
  };
}
