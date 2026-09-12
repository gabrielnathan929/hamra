_: ''
  # Focus
  bindsym $mod+Left           focus left
  bindsym $mod+Right          focus right
  bindsym $mod+Up             focus up
  bindsym $mod+Down           focus down

  # Swap (NOTE: Sway's move does not swap like Hyprland)
  bindsym $mod+Shift+Left     move left
  bindsym $mod+Shift+Right    move right
  bindsym $mod+Shift+Up       move up
  bindsym $mod+Shift+Down     move down

  # Window move to monitor
  bindsym $mod+Shift+Alt+Left   move container to output left
  bindsym $mod+Shift+Alt+Right  move container to output right
  bindsym $mod+Shift+Alt+Up     move container to output up
  bindsym $mod+Shift+Alt+Down   move container to output down

  # NOTE: Sway does not have Hyprland-style groups (into_group/out_of_group,
  # group toggle, group nav, group scroll, group index, etc.)
''
