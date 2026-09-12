_: ''
  -- Window operations
  hl.bind(
    "SUPER+Q",
    hl.dsp.window.close()
  )
  hl.bind(
    "SUPER+J",
    hl.dsp.layout("togglesplit")
  )
  hl.bind(
    "SUPER+P",
    hl.dsp.window.pseudo()
  )
  hl.bind(
    "SUPER+T",
    hl.dsp.window.float({ action = "toggle" })
  )
  hl.bind(
    "SUPER+SHIFT+F",
    hl.dsp.window.fullscreen({ mode = "fullscreen" })
  )
  hl.bind(
    "ALT+F",
    hl.dsp.window.fullscreen({ mode = "maximized" })
  )

  -- Resize (arrow keys)
  -- Ctrl = base modifier to avoid conflict with SUPER+ARROW (focus)
  local resizeSteps = {
    { "CTRL+",       100 },
    { "CTRL+ALT+",   25  },
    { "CTRL+SHIFT+", 300 },
  }
  local resizeDirs = {
    { "LEFT",  -1,  0 },
    { "RIGHT",  1,  0 },
    { "UP",     0, -1 },
    { "DOWN",   0,  1 },
  }
  for _, s in ipairs(resizeSteps) do
    local mod, mag = s[1], s[2]
    for _, d in ipairs(resizeDirs) do
      hl.bind(
        "SUPER+" .. mod .. d[1],
        hl.dsp.window.resize({ x = d[2] * mag, y = d[3] * mag, relative = true })
      )
    end
  end
''
