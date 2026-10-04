_: ''
  // Session
  Alt+L                   { spawn-sh "noctalia msg session lock"; }
  Mod+Shift+L             { spawn-sh "noctalia msg session lock-and-suspend"; }
  Mod+Ctrl+Alt+L          { spawn-sh "noctalia msg session logout"; }
  Mod+Ctrl+Alt+R          { spawn-sh "noctalia msg session reboot"; }
  Mod+Ctrl+Alt+S    { spawn-sh "noctalia msg session shutdown"; }
''
