_: ''
  XF86AudioRaiseVolume    { spawn-sh "noctalia msg volume-up"; }
  XF86AudioLowerVolume    { spawn-sh "noctalia msg volume-down"; }
  XF86AudioMute           { spawn-sh "noctalia msg volume-mute"; }

  Mod+Ctrl+Shift+Up       { spawn-sh "noctalia msg mic-volume-up"; }
  Mod+Ctrl+Shift+Down     { spawn-sh "noctalia msg mic-volume-down"; }
  Mod+Ctrl+Shift+M        { spawn-sh "noctalia msg mic-mute"; }
''
