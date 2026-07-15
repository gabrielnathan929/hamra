_: ''
  -- Mouse
  hl.bind(
    "SUPER+mouse_down",
    hl.dsp.focus({ workspace = "m+1" })
  )
  hl.bind(
    "SUPER+mouse_up",
    hl.dsp.focus({ workspace = "m-1" })
  )
  hl.bind(
    "SUPER+mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
  )
  hl.bind(
    "SUPER+mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
  )

  -- Touchpad
  hl.bind(
    "SUPER + CTRL",
    hl.dsp.window.drag(), { mouse = true }
  )
  hl.bind(
    "SUPER + ALT",
    hl.dsp.window.resize(), { mouse = true }
  )
''
