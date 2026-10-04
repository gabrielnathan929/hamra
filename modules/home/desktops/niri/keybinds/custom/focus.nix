_: ''
  // Focus
  Mod+Left                { focus-column-left; }
  Mod+Right               { focus-column-right; }
  Mod+Up                  { focus-window-up; }
  Mod+Down                { focus-window-down; }

  // Swap
  Mod+Shift+Left          { move-column-left; }
  Mod+Shift+Right         { move-column-right; }
  Mod+Shift+Up            { move-window-up; }
  Mod+Shift+Down          { move-window-down; }

  // Window move to monitor
  Mod+Shift+Alt+Left      { move-column-to-monitor "left"; }
  Mod+Shift+Alt+Right     { move-column-to-monitor "right"; }
  Mod+Shift+Alt+Up        { move-column-to-monitor "up"; }
  Mod+Shift+Alt+Down      { move-column-to-monitor "down"; }

  // Focus monitor
  Mod+Shift+Period        { focus-monitor-right; }
  Mod+Shift+Comma         { focus-monitor-left; }

  // NOTE: Niri does not have window groups (Hyprland's into_group / group operations)
''
