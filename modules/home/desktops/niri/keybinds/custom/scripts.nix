{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  // Scripts
  Mod+Ctrl+Alt+m           { spawn-sh "${terminal} -e setup-nas"; }
''
