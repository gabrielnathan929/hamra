{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  bindsym $mod+Alt+m              exec ${terminal} -e setup-nas
  bindsym $mod+K                  exec ${terminal} -e bash -c 'keys sway | fzf --reverse'
  bindsym $mod+Ctrl+k             exec ${terminal} -e bash -c 'keys herdr | fzf --reverse'
  bindsym $mod+Alt+k              exec ${terminal} -e bash -c 'keys tmux | fzf --reverse'
''
