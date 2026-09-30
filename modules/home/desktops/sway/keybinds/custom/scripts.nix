{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  # Scripts
  bindsym $mod+Ctrl+Alt+m         exec ${terminal} -e setup-nas
''
