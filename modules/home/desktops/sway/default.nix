{
  lib,
  pkgs,
  config,
  keyboard,
  displays,
  env,
  wayvnc,
  wallpaperPath,
  ...
}: let
  monitorsPart = import ./monitors {inherit displays lib;};
  configPart = import ./settings {inherit keyboard;};
  noctaliaPart = import ./noctalia {
    inherit displays lib;
  };
  keybindsPart = import ./keybinds {inherit config lib env pkgs;};
in {
  xdg.configFile."sway/config".text = ''
    ${monitorsPart}
    ${configPart}
    ${noctaliaPart}
    ${keybindsPart}

    ${lib.optionalString wayvnc "exec systemctl --user start wayvnc.service"}
  '';
}
