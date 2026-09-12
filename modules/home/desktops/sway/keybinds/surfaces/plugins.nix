_: ''
  # Plugins
  bindsym Alt+b exec $ipc plugin noctalia/bongocat:cat focused toggle
  bindsym Alt+e exec $ipc panel-toggle launcher '/emo '
  bindsym Alt+m exec $ipc panel-toggle gabrielnathan929/myanimelist:browser
  bindsym Alt+n exec $ipc panel-toggle noctalia/notes:panel
  bindsym Alt+k exec $ipc panel-toggle launcher '/kao '
  bindsym Alt+t exec $ipc panel-toggle launcher '/tr '
  bindsym Alt+v exec $ipc panel-toggle noctalia/mpvpaper:picker
  bindsym Alt+w exec $ipc panel-toggle noctalia/wallhaven:browser
  bindsym Alt+Print exec $ipc plugin noctalia/screen_recorder:service all toggle
  bindsym $mod+Alt+Print exec $ipc panel-toggle oldirtty/color_picker:panel
  bindsym $mod+Ctrl+Alt+Print exec $ipc plugin noctalia/screen_recorder:service all replay-save
''
