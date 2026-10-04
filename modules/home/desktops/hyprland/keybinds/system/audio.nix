_: ''
  -- Volume
  hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"))
  hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"))
  hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"))

  -- Microphone
  hl.bind("SUPER+CTRL+SHIFT+UP", hl.dsp.exec_cmd("noctalia msg mic-volume-up"))
  hl.bind("SUPER+CTRL+SHIFT+DOWN", hl.dsp.exec_cmd("noctalia msg mic-volume-down"))
  hl.bind("SUPER+CTRL+SHIFT+M", hl.dsp.exec_cmd("noctalia msg mic-mute"))
''
