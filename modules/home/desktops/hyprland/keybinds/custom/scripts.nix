{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  hl.bind("ALT+SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle gabrielnathan929/hamra-control:main"))
  hl.bind("SUPER+ALT+m", hl.dsp.exec_cmd("${terminal} -e setup-nas"))
''
