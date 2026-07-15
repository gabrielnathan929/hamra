{pkgs, ...}: ''
  // Window cycle forward/backward
  Mod+Tab                 { focus-column-right; }
  Mod+Shift+Tab           { focus-column-left; }

  // Workspace navigation via scroll already in mouse.nix.
  // Workspace back-and-forth via ALT+TAB window-switcher in shell.nix.

  // Workspaces 1-10
  Mod+1                   { focus-workspace 1; }
  Mod+2                   { focus-workspace 2; }
  Mod+3                   { focus-workspace 3; }
  Mod+4                   { focus-workspace 4; }
  Mod+5                   { focus-workspace 5; }
  Mod+6                   { focus-workspace 6; }
  Mod+7                   { focus-workspace 7; }
  Mod+8                   { focus-workspace 8; }
  Mod+9                   { focus-workspace 9; }
  Mod+0                   { focus-workspace 10; }

  // NOTE: Niri's move-column-to-workspace always follows (no follow=false).
  // The Alt+Shift variant below is identical — kept for consistency with Hyprland.
  Mod+Shift+1             { move-column-to-workspace 1; }
  Mod+Shift+2             { move-column-to-workspace 2; }
  Mod+Shift+3             { move-column-to-workspace 3; }
  Mod+Shift+4             { move-column-to-workspace 4; }
  Mod+Shift+5             { move-column-to-workspace 5; }
  Mod+Shift+6             { move-column-to-workspace 6; }
  Mod+Shift+7             { move-column-to-workspace 7; }
  Mod+Shift+8             { move-column-to-workspace 8; }
  Mod+Shift+9             { move-column-to-workspace 9; }
  Mod+Shift+0             { move-column-to-workspace 10; }

  Mod+Shift+Alt+1         { move-column-to-workspace 1; }
  Mod+Shift+Alt+2         { move-column-to-workspace 2; }
  Mod+Shift+Alt+3         { move-column-to-workspace 3; }
  Mod+Shift+Alt+4         { move-column-to-workspace 4; }
  Mod+Shift+Alt+5         { move-column-to-workspace 5; }
  Mod+Shift+Alt+6         { move-column-to-workspace 6; }
  Mod+Shift+Alt+7         { move-column-to-workspace 7; }
  Mod+Shift+Alt+8         { move-column-to-workspace 8; }
  Mod+Shift+Alt+9         { move-column-to-workspace 9; }
  Mod+Shift+Alt+0         { move-column-to-workspace 10; }

  // NOTE: Niri does not have scratchpad or tab groups like Hyprland.
  // Groups-specific Hyprland binds not ported:
  //   SUPER+G                      (group.toggle)
  //   SUPER+ALT+G                  (move out_of_group)
  //   SUPER+ALT+TAB                (group.next)
  //   SUPER+CTRL+LEFT/RIGHT        (group.prev/next)
  //   SUPER+ALT+mouse_down/up      (group scroll)
  //   SUPER+ALT+1-5                (group.active index)
  //   SUPER+ALT+LEFT/RIGHT/UP/DOWN (into_group direction)
''
