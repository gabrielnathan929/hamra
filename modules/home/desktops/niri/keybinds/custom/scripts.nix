{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  Mod+Alt+m                { spawn-sh "${terminal} -e setup-nas"; }
  Mod+K                    { spawn-sh "${terminal} -e bash -c 'keys niri | fzf --reverse'"; }
  Mod+Ctrl+K               { spawn-sh "${terminal} -e bash -c 'keys herdr | fzf --reverse'"; }
  Mod+Alt+K                { spawn-sh "${terminal} -e bash -c 'keys tmux | fzf --reverse'"; }
''
