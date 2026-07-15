{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.hardware;
in
  lib.mkIf cfg.touchpad {
    services.libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
      };
    };
  }
