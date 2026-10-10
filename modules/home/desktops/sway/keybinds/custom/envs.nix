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

  bindsym $mod+Alt+t        exec ${terminal} --app-id=console -e btop
  bindsym $mod+Shift+d        exec ${terminal} --app-id=console -e lazydocker
  bindsym $mod+Shift+g        exec ${terminal} --app-id=console -e lazygit
  bindsym $mod+h              exec ${terminal} -e herdr
  bindsym $mod+Shift+t        exec ${terminal} -e tmux new-session -A -s main
''
