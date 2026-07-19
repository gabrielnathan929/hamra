{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.qbittorrent;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.media.qbittorrent = mkOption {
    type = types.bool;
    default = false;
    description = "Enable qBittorrent (BitTorrent client).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.qbittorrent];
}
