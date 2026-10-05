_: ''
  local function split_toggle()
    local active = hl.get_active_workspace()
    if active == nil then
      return
    end

    if active.tiled_layout == "scrolling" then
      local result = hl.dispatch(hl.dsp.layout("consume_or_expel next"))
      if type(result) ~= "table" or result.ok ~= true then
        hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
      end
    else
      hl.dispatch(hl.dsp.layout("togglesplit"))
    end
  end

  hl.bind(
    "SUPER+Q",
    hl.dsp.window.close()
  )
  hl.bind("SUPER+J", split_toggle)
  hl.bind(
    "SUPER+P",
    hl.dsp.window.pseudo()
  )
  hl.bind(
    "SUPER+T",
    hl.dsp.window.float({ action = "toggle" })
  )
  hl.bind(
    "SUPER+O",
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
