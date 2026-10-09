{
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
  browser = lib.getExe env.browser;
  filemanager = lib.getExe env.filemanager;
  editor = lib.getExe env.editor;
in ''
  Mod+Return              { spawn "${terminal}"; }
  Mod+E                   { spawn "${filemanager}"; }
  Mod+B                   { spawn "${browser}"; }
  Mod+Shift+B             { spawn-sh "${browser} --private-window"; }
  Mod+Shift+N             { spawn-sh "${terminal} -e ${editor}"; }

  Mod+Ctrl+Print         { spawn-sh "ocr-screenshot"; }

  Mod+Alt+T               { spawn-sh "${terminal} --app-id=hamra-tui -e btop"; }
  Mod+Shift+H             { spawn-sh "${terminal} -e herdr"; }
  Mod+Shift+T             { spawn-sh "${terminal} -e tmux new-session -A -s main"; }

  Mod+Shift+D             { spawn-sh "${terminal} --app-id=hamra-tui -e lazydocker"; }

  Mod+Shift+G             { spawn-sh "${terminal} --app-id=hamra-tui -e lazygit"; }
''
