_: ''
  # Mouse
  bindsym $mod+button4     workspace next
  bindsym $mod+button5     workspace prev
  bindsym --whole-window $mod+button1  mouse
  bindsym $mod+button3      resize

  # Touchpad (hold Mod+Ctrl to drag, Mod+Alt to resize)
  # NOTE: Hyprland's { mouse = true } allows drag/resize on touchpad MOVEMENT
  # (no click needed). Sway requires a CLICK/TAP on the touchpad.
  bindsym --whole-window $mod+Ctrl+button1  mouse
  bindsym --whole-window $mod+Alt+button1   resize
''
