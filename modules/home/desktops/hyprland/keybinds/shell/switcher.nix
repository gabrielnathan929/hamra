{pkgs, ...}: let
  altTab = import ../scripts/alt-tab.nix {inherit pkgs;};
in ''
  hl.bind("ALT+TAB", hl.dsp.exec_cmd("${altTab} next"))
  hl.bind("ALT+SHIFT+TAB", hl.dsp.exec_cmd("${altTab} prev"))
  hl.bind("SUPER+W", hl.dsp.exec_cmd("noctalia msg window-switcher"))
''
