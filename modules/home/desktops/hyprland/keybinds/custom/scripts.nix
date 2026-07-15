{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  hl.bind("SUPER+CTRL+ALT+g", hl.dsp.exec_cmd("${terminal} -e setup-gpg"))
  hl.bind("SUPER+CTRL+ALT+h", hl.dsp.exec_cmd("${terminal} -e setup-ssh"))
  hl.bind("SUPER+ALT+f", hl.dsp.exec_cmd("${terminal} -e flatpak-install"))
  hl.bind("SUPER+CTRL+ALT+f", hl.dsp.exec_cmd("${terminal} -e flatpak-remove"))
''
