_: ''
  # Window operations
  bindsym $mod+Q            kill
  bindsym $mod+J            layout toggle split
  # NOTE: Sway does not have pseudo-tiling, using focus mode_toggle
  bindsym $mod+P            focus mode_toggle
  bindsym $mod+T            floating toggle
  bindsym $mod+Shift+F      fullscreen
  bindsym Mod1+F            fullscreen toggle
  # NOTE: Sway only has a single fullscreen toggle, no client/maximized modes

  # Window resize (keyboard)
  # NOTE: Hyprland uses Q/W for resize but $mod+Q is kill here.
  # Using arrow keys instead. Ctrl = 100px, Alt = 25px fine step.
  # Coarse step (300px) skipped because $mod+Ctrl+Shift+Up/Down
  # clash with mic bindings.
  bindsym $mod+Ctrl+Left     resize shrink width 100px
  bindsym $mod+Ctrl+Right    resize grow width 100px
  bindsym $mod+Ctrl+Up       resize shrink height 100px
  bindsym $mod+Ctrl+Down     resize grow height 100px
  bindsym $mod+Alt+Left      resize shrink width 25px
  bindsym $mod+Alt+Right     resize grow width 25px
  bindsym $mod+Alt+Up        resize shrink height 25px
  bindsym $mod+Alt+Down      resize grow height 25px
''
