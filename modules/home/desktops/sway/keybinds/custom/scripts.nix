{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  bindsym $mod+Alt+m              exec ${terminal} -e setup-nas
  bindsym $mod+K                  exec ${terminal} -e bash -c 'hamra-keybinds sway | fzf --reverse'
''
