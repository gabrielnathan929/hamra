{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  // Scripts
  Alt+Space                { spawn-sh "noctalia msg panel-toggle gabrielnathan929/hamra-control:main"; }
  Mod+Ctrl+Alt+m           { spawn-sh "${terminal} -e setup-nas"; }
''
