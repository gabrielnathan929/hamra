_: ''
  -- Brightness
  hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"))
  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"))

  -- Sleep
  hl.bind("XF86Sleep", hl.dsp.exec_cmd("noctalia msg session suspend"))

  -- DPMS
  hl.bind("SUPER+CTRL+M", hl.dsp.exec_cmd("noctalia msg dpms-on"))
  hl.bind("SUPER+CTRL+ALT+M", hl.dsp.exec_cmd("noctalia msg dpms-off"))
''
