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
  bindsym $mod+Return       exec ${terminal}
  bindsym $mod+E            exec ${filemanager}
  bindsym $mod+B            exec ${browser}
  bindsym $mod+Shift+B      exec ${browser} --private-window
  bindsym $mod+Shift+n      exec ${terminal} -e ${editor}

  bindsym $mod+Ctrl+Print  exec ocr-screenshot

  bindsym $mod+Alt+t        exec ${terminal} -e btop
  bindsym $mod+h              exec ${terminal} -e herdr
  bindsym $mod+Shift+t        exec ${terminal} -e tmux new-session -A -s main
''
