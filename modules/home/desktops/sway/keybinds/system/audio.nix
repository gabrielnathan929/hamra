_: ''
  # Volume
  bindsym XF86AudioRaiseVolume  exec $ipc volume-up
  bindsym XF86AudioLowerVolume  exec $ipc volume-down
  bindsym XF86AudioMute         exec $ipc volume-mute

  # Microphone
  bindsym $mod+Ctrl+Shift+Up   exec $ipc mic-volume-up
  bindsym $mod+Ctrl+Shift+Down exec $ipc mic-volume-down
  bindsym $mod+Ctrl+Shift+m    exec $ipc mic-mute
''
