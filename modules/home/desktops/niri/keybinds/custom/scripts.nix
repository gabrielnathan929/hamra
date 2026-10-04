{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  Mod+Alt+m                { spawn-sh "${terminal} -e setup-nas"; }
  Mod+K                    { spawn-sh "${terminal} -e bash -c 'hamra-keybinds niri | fzf --reverse'"; }
  Mod+Ctrl+K               { spawn-sh "${terminal} -e bash -c 'hamra-keybinds herdr | fzf --reverse'"; }
  Mod+Alt+K                { spawn-sh "${terminal} -e bash -c 'hamra-keybinds tmux | fzf --reverse'"; }
''
