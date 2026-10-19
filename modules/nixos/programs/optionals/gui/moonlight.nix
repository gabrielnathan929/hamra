{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.moonlight;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.moonlight = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Moonlight, the game stream client for Sunshine.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.moonlight-qt];
  };
}
