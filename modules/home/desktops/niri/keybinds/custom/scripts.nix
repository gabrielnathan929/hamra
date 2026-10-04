{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  Mod+Alt+m                { spawn-sh "${terminal} -e setup-nas"; }
  Mod+K                    { spawn-sh "${terminal} -e bash -c 'hamra-keybinds niri | fzf --reverse'"; }
''
