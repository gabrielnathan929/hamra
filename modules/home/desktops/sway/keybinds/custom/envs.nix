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
  # Envs
  bindsym $mod+Return       exec ${terminal}
  bindsym $mod+E            exec ${filemanager}
  bindsym $mod+B            exec ${browser}
  bindsym $mod+Shift+B      exec ${browser} --private-window

  # OCR
  bindsym $mod+Ctrl+Print  exec ocr-screenshot

  # Btop
  bindsym $mod+Alt+t        exec ${terminal} -e btop
''
