_: ''
  // Toggles
  XF86WLAN                { spawn-sh "noctalia msg wifi-toggle"; }
  XF86RFKill              { spawn-sh "noctalia msg wifi-toggle"; }
  Mod+Ctrl+W              { spawn-sh "noctalia msg wifi-toggle"; }
  Mod+Ctrl+N              { spawn-sh "noctalia msg nightlight-toggle"; }
  Mod+Ctrl+B              { spawn-sh "noctalia msg bluetooth-toggle"; }
  Mod+Ctrl+C              { spawn-sh "noctalia msg caffeine-toggle"; }
  Mod+Ctrl+P              { spawn-sh "noctalia msg power-cycle"; }
''
