_: ''
  // Brightness
  XF86MonBrightnessUp     { spawn-sh "noctalia msg brightness-up"; }
  XF86MonBrightnessDown   { spawn-sh "noctalia msg brightness-down"; }

  // Sleep
  XF86Sleep               { spawn-sh "noctalia msg session suspend"; }

  // DPMS
  Mod+Ctrl+M              { spawn-sh "noctalia msg dpms-on"; }
  Mod+Ctrl+Alt+M          { spawn-sh "noctalia msg dpms-off"; }
''
