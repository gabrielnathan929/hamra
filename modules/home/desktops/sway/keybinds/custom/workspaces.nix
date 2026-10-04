{pkgs, ...}: let
  next = import ../scripts/workspace-next.nix {inherit pkgs;};
  prev = import ../scripts/workspace-prev.nix {inherit pkgs;};
in ''
  # Active workspace navigation (skip empty)
  bindsym $mod+Tab           exec ${next}
  bindsym $mod+Shift+Tab     exec ${prev}
  bindsym $mod+Ctrl+Tab      workspace back_and_forth

  # Window cycle (ALT+TAB assigned to window-switcher via shell.nix)

  # Workspaces 1-10
  bindsym $mod+1             workspace number 1
  bindsym $mod+2             workspace number 2
  bindsym $mod+3             workspace number 3
  bindsym $mod+4             workspace number 4
  bindsym $mod+5             workspace number 5
  bindsym $mod+6             workspace number 6
  bindsym $mod+7             workspace number 7
  bindsym $mod+8             workspace number 8
  bindsym $mod+9             workspace number 9
  bindsym $mod+0             workspace number 10

  bindsym $mod+Shift+1       move container to workspace number 1
  bindsym $mod+Shift+2       move container to workspace number 2
  bindsym $mod+Shift+3       move container to workspace number 3
  bindsym $mod+Shift+4       move container to workspace number 4
  bindsym $mod+Shift+5       move container to workspace number 5
  bindsym $mod+Shift+6       move container to workspace number 6
  bindsym $mod+Shift+7       move container to workspace number 7
  bindsym $mod+Shift+8       move container to workspace number 8
  bindsym $mod+Shift+9       move container to workspace number 9
  bindsym $mod+Shift+0       move container to workspace number 10

  bindsym $mod+Shift+Alt+1   move container to workspace number 1
  bindsym $mod+Shift+Alt+2   move container to workspace number 2
  bindsym $mod+Shift+Alt+3   move container to workspace number 3
  bindsym $mod+Shift+Alt+4   move container to workspace number 4
  bindsym $mod+Shift+Alt+5   move container to workspace number 5
  bindsym $mod+Shift+Alt+6   move container to workspace number 6
  bindsym $mod+Shift+Alt+7   move container to workspace number 7
  bindsym $mod+Shift+Alt+8   move container to workspace number 8
  bindsym $mod+Shift+Alt+9   move container to workspace number 9
  bindsym $mod+Shift+Alt+0   move container to workspace number 10

  # Scratchpad (Sway has native scratchpad support)
  bindsym $mod+S            scratchpad show
  bindsym $mod+Alt+S        move scratchpad

  # NOTE: Sway does not have Hyprland-style groups. All group-specific Hyprland
  # binds not ported (SUPER+G toggle, SUPER+ALT+G out_of_group,
  # SUPER+ALT+TAB group nav, SUPER+ALT+mouse group scroll, SUPER+ALT+1-5
  # group index, SUPER+ALT+ARROW into_group direction, etc.)
''
