{
  lib,
  pkgs,
  config,
  keyboard,
  displays,
  env,
  wayvnc,
  ...
}: let
  monitorsPart = import ./monitors {inherit displays lib;};
  settingsPart = import ./settings {inherit keyboard;};
  rulesPart = import ./rules.nix {};
  noctaliaPart = import ./noctalia {inherit displays lib;};
  keybindsPart = import ./keybinds {inherit config lib pkgs env;};
in {
  xdg.configFile."hypr/hyprland.lua" = {
    force = true;
    text = ''
      ${monitorsPart}
      ${settingsPart}
      ${rulesPart}
      ${noctaliaPart}
      ${keybindsPart}

      -- Startup
      hl.on("hyprland.start", function()
        hl.exec_cmd("noctalia")
        ${
        if wayvnc
        then ''hl.exec_cmd("systemctl --user start wayvnc.service")''
        else ""
      }
      end)
    '';
  };

  hamra.keybinds.hyprland = import ./keybinds/panel.nix;
}
