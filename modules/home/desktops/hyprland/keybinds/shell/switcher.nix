{pkgs, ...}: let
  windowSwitcher = import ../scripts/window-switcher.nix {inherit pkgs;};
in ''
  hl.bind("ALT+TAB", hl.dsp.exec_cmd("${windowSwitcher}"))
  hl.bind("ALT+SHIFT+TAB", hl.dsp.exec_cmd("${windowSwitcher}"))
  hl.bind("SUPER+W", hl.dsp.exec_cmd("${windowSwitcher}"))
''
