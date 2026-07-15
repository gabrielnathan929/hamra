{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
  browser = lib.getExe env.browser;
  filemanager = lib.getExe env.filemanager;
in ''
  // Envs
  Mod+Return              { spawn "${terminal}"; }
  Mod+E                   { spawn "${filemanager}"; }
  Mod+B                   { spawn "${browser}"; }
  Mod+Shift+B             { spawn-sh "${browser} --private-window"; }

  // OCR
  Mod+Ctrl+Print         { spawn-sh "ocr-screenshot"; }

  // Btop
  Mod+Alt+T               { spawn-sh "${terminal} -e btop"; }

  // Lazydocker
  Mod+Shift+D             { spawn-sh "${terminal} -e lazydocker"; }

  // Lazygit
  Mod+Shift+G             { spawn-sh "${terminal} -e lazygit"; }
''
