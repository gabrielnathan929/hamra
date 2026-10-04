{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  hl.bind("SUPER+ALT+m", hl.dsp.exec_cmd("${terminal} -e setup-nas"))
  hl.bind("SUPER+K", hl.dsp.exec_cmd("${terminal} -e bash -c 'hamra-keybinds hyprland | fzf --reverse'"))
  hl.bind("SUPER+CTRL+K", hl.dsp.exec_cmd("${terminal} -e bash -c 'hamra-keybinds herdr | fzf --reverse'"))
  hl.bind("SUPER+ALT+K", hl.dsp.exec_cmd("${terminal} -e bash -c 'hamra-keybinds tmux | fzf --reverse'"))
''
