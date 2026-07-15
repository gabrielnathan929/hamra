_: ''
  # Session
  bindsym Alt+l               exec $ipc session lock
  bindsym $mod+Shift+l        exec $ipc session lock-and-suspend
  bindsym $mod+Ctrl+Alt+l     exec $ipc session logout
  bindsym $mod+Ctrl+Alt+r     exec $ipc session reboot
  bindsym $mod+Ctrl+Alt+s     exec $ipc session shutdown
''
