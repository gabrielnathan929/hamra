{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  hl.bind("SUPER+ALT+m", hl.dsp.exec_cmd("${terminal} --app-id=console -e setup-nas"))
  hl.bind("SUPER+K", hl.dsp.exec_cmd("${terminal} --app-id=console -e bash -c 'keys hyprland | fzf --reverse'"))
  hl.bind("SUPER+CTRL+K", hl.dsp.exec_cmd("${terminal} --app-id=console -e bash -c 'keys herdr | fzf --reverse'"))
  hl.bind("SUPER+ALT+K", hl.dsp.exec_cmd("${terminal} --app-id=console -e bash -c 'keys tmux | fzf --reverse'"))
''
