{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.wine;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.optionals.games.wine = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Wine (Windows compatibility layer, 32/64-bit via WoW64) with Winetricks.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [wineWow64Packages.stable winetricks];

    home-manager.users.${userName}.xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/x-ms-dos-executable" = "wine.desktop";
        "application/x-msi" = "wine.desktop";
        "application/x-ms-shortcut" = "wine.desktop";
      };
    };
  };
}
