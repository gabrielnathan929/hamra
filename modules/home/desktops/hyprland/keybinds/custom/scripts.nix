{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  hl.bind("SUPER+ALT+m", hl.dsp.exec_cmd("${terminal} -e setup-nas"))
''
