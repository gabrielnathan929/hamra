# Shared machine baseline — no personal values live here (they belong to
# hosts/profiles/<owner>/). Forks pull updates to this layer without conflicts.
#
# Tier contract (option priority):
#   module declaration defaults (1500) < hosts/common (hamraLib.mkBase, 1000)
#   < hosts/profiles/<owner> (mkDefault, 900) < hosts/<machine> (plain, 100)
{
  config,
  inputs,
  lib,
  ...
}: let
  hamraLib = import ../../modules/lib {inherit lib;};
in {
  imports = [
    ./core/audio.nix
    ./core/boot.nix
    ./core/desktop.nix
    ./core/display-manager.nix
    ./core/displays.nix
    ./core/envs/android.nix
    ./core/hardware.nix
    ./core/keyboard.nix
    ./core/maintenance.nix
    ./core/networking.nix
    ./core/printing.nix
    ./core/security.nix
    ./programs/flatpak.nix
    ./programs/packages.nix
    ./programs/webapps.nix
  ];

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";

  home-manager = {
    extraSpecialArgs = {
      inherit inputs hamraLib;
      wallpaperPath = config.hamra.theme.wallpaper;
      themesDir = ../../modules/nixos/core/theme/themes;
      keyboard = config.hamra.keyboard;
      desktop = config.hamra.desktop.default;
      displays = config.hamra.displays;
      wayvnc = config.hamra.programs.optionals.services.wayvnc;
      env = config.hamra.env;
    };
    users.${config.hamra.users.userName} = {
      home.stateVersion = "26.05";
      imports = [../../modules/home];
    };
  };
}
