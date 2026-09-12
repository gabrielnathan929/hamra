{
  lib,
  pkgs,
  config,
  keyboard,
  displays,
  env,
  ...
}: let
  monitorsPart = import ./monitors {inherit displays lib;};
  settingsPart = import ./settings {inherit keyboard;};
  noctaliaPart = import ./noctalia {};
  keybindsPart = import ./keybinds {inherit config lib env pkgs;};
in {
  xdg.configFile."niri/config.kdl" = {
    force = true;
    text = ''
      ${monitorsPart}

      ${settingsPart}

      ${noctaliaPart}

      ${keybindsPart}
    '';
  };
}
