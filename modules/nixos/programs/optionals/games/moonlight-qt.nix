{config, lib, pkgs, ...}: let
  cfg = config.hamra.programs.optionals.games.moonlight-qt;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.moonlight-qt = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Moonlight-QT game streaming client.";
  };
}