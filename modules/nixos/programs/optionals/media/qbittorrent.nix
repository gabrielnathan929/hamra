{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.qbittorrent;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.optionals.media.qbittorrent = mkOption {
    type = types.bool;
    default = false;
    description = "Enable qBittorrent (BitTorrent client).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.qbittorrent];

    home-manager.users.${userName}.xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
        "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
      };
    };
  };
}
