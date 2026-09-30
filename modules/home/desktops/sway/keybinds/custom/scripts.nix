{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  # Scripts
  bindsym Alt+space          exec noctalia msg panel-toggle gabrielnathan929/hamra-control:main
  bindsym $mod+Ctrl+Alt+m         exec ${terminal} -e setup-nas
''
