_: ''
  -- Navigation
  hl.bind("SUPER+left",             hl.dsp.focus({ direction = "left" }))
  hl.bind("SUPER+right",            hl.dsp.focus({ direction = "right" }))
  hl.bind("SUPER+up",               hl.dsp.focus({ direction = "up" }))
  hl.bind("SUPER+down",             hl.dsp.focus({ direction = "down" }))

  -- Windows
  hl.bind("SUPER+Q",                hl.dsp.window.close())
  hl.bind("SUPER+F",                hl.dsp.window.float({ action = "toggle" }))
  hl.bind("SUPER+M",                hl.dsp.exec_cmd("hyprctl dispatch fullscreen"))
  hl.bind("SUPER+S",                hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace"))
  hl.bind("SUPER+ALT+S",            hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace special"))

  -- Applications
  hl.bind("SUPER+Return",           hl.dsp.exec_cmd("kitty"))
  hl.bind("SUPER+period",           hl.dsp.exec_cmd(ipc .. " panel-toggle control-center"))
  hl.bind("SUPER+SHIFT+O",          hl.dsp.exec_cmd("ocr-screenshot"))

  -- Workspaces
  for i = 1, 9 do
    hl.bind("SUPER+" .. i,          hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER+SHIFT+" .. i,    hl.dsp.window.move({ workspace = i }))
  end
''
