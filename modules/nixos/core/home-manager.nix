{
  config,
  inputs,
  hamraLib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.home-manager];

  nix.settings.trusted-users = [config.hamra.users.userName];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs hamraLib;
      wallpaperPath = config.hamra.theme.wallpaper;
      themesDir = ./theme/themes;
      keyboard = config.hamra.keyboard;
      desktop = config.hamra.desktop.default;
      displays = config.hamra.displays;
      wayvnc = config.hamra.programs.optionals.services.wayvnc;
      env = config.hamra.env;
    };
    users.${config.hamra.users.userName} = {
      home.stateVersion = "26.05";
      imports = [../../home];
    };
  };
}
