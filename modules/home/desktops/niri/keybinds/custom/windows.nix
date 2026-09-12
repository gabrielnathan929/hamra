_: ''
  // Window operations
  Mod+Q                   { close-window; }
  Mod+F                   { toggle-window-floating; }
  Mod+J                   { maximize-column; }
  Mod+Shift+F             { fullscreen-window; }
  Alt+F                   { fullscreen-window; }

  // Window resize (keyboard)
  // NOTE: Hyprland uses Q/W for resize but Mod+Q is close-window here.
  // Using Niri's recommended Ctrl+Arrow approach instead.
  //   Ctrl = 10% step, Alt = 5% fine step
  //   Coarse step (Hyprland's Ctrl variant, 300px) skipped because
  //   Mod+Ctrl+Shift+Up/Down clash with mic bindings.
  Mod+Ctrl+Left           { set-column-width "-10%";  }
  Mod+Ctrl+Right          { set-column-width "+10%";  }
  Mod+Ctrl+Up             { set-window-height "-10%"; }
  Mod+Ctrl+Down           { set-window-height "+10%"; }
  Mod+Alt+Left            { set-column-width "-5%";   }
  Mod+Alt+Right           { set-column-width "+5%";   }
  Mod+Alt+Up              { set-window-height "-5%";  }
  Mod+Alt+Down            { set-window-height "+5%";  }
''
