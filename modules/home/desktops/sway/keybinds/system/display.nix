_: ''
  bindsym XF86MonBrightnessUp    exec $ipc brightness-up
  bindsym XF86MonBrightnessDown  exec $ipc brightness-down

  bindsym XF86Sleep               exec $ipc session suspend

  bindsym $mod+Ctrl+m          exec $ipc dpms-on
  bindsym $mod+Ctrl+Alt+m      exec $ipc dpms-off
''
