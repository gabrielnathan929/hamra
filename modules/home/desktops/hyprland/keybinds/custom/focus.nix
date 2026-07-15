_: ''
  local dirs = {
    { "LEFT",  "l" },
    { "RIGHT", "r" },
    { "UP",    "u" },
    { "DOWN",  "d" },
  }

  -- Focus + swap + monitor move + group move
  for _, d in ipairs(dirs) do
    hl.bind(
      "SUPER+" .. d[1],
      hl.dsp.focus({ direction = d[2] })
    )
    hl.bind(
      "SUPER+SHIFT+" .. d[1],
      hl.dsp.window.swap({ direction = d[2] })
    )
    hl.bind(
      "SUPER+SHIFT+ALT+" .. d[1],
      hl.dsp.workspace.move({ monitor = d[2] })
    )
    hl.bind(
      "SUPER+ALT+" .. d[1],
      hl.dsp.window.move({ into_group = d[2] })
    )
  end
''
