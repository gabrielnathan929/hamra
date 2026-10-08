{
  config,
  lib,
  pkgs,
  ...
}: let
  displayManager = config.hamra.displayManager;
in {
  config = lib.mkIf (displayManager.default == "greetd") {
    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 24;
          path = pkgs.bibata-cursors;
        };
      };
    };
  };
}
