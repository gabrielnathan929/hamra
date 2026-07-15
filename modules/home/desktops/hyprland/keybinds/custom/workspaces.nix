_: let
  next = import ../scripts/workspace-next.nix {};
  prev = import ../scripts/workspace-prev.nix {};
in ''
  -- Active workspace navigation (skip empty)
  hl.bind("SUPER+TAB", hl.dsp.exec_cmd([[
    ${next}
  ]]))
  hl.bind("SUPER+SHIFT+TAB", hl.dsp.exec_cmd([[
    ${prev}
  ]]))
  hl.bind(
    "SUPER+CTRL+TAB",
    hl.dsp.focus({ workspace = "previous" }))

  -- Window cycle (commented out — using Noctalia switcher via shell/switcher.nix)
  -- hl.bind("ALT+TAB", hl.dsp.window.cycle_next())
  -- hl.bind("ALT+SHIFT+TAB", hl.dsp.window.cycle_next({ next = false }))

  -- Workspaces (1-10)
  for workspace = 1, 10 do
    local key = "code:" .. tostring(workspace + 9)
    hl.bind(
      "SUPER+" .. key,
      hl.dsp.focus({ workspace = tostring(workspace) })
    )
    hl.bind(
      "SUPER+SHIFT+" .. key,
      hl.dsp.window.move({ workspace = tostring(workspace) })
    )
    hl.bind(
      "SUPER+SHIFT+ALT+" .. key,
      hl.dsp.window.move({ workspace = tostring(workspace), follow = false })
    )
  end

  -- Scratchpad
  hl.bind(
    "SUPER+S",
    hl.dsp.workspace.toggle_special("scratchpad")
  )
  hl.bind(
    "SUPER+ALT+S",
    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })
  )

  -- Groups
  hl.bind(
    "SUPER+G",
    hl.dsp.group.toggle()
  )
  hl.bind(
    "SUPER+ALT+G",
    hl.dsp.window.move({ out_of_group = true })
  )
  hl.bind(
    "SUPER+ALT+TAB",
    hl.dsp.group.next()
  )
  hl.bind(
    "SUPER+ALT+SHIFT+TAB",
    hl.dsp.group.prev()
  )
  -- NOTE: SUPER+CTRL+LEFT/RIGHT removed -- conflict with arrow-key resize.
  -- Use SUPER+ALT+TAB / SUPER+ALT+SHIFT+TAB for group nav instead.
  hl.bind(
    "SUPER+ALT+mouse_down",
    hl.dsp.group.next()
  )
  hl.bind(
    "SUPER+ALT+mouse_up",
    hl.dsp.group.prev()
  )

  for index = 1, 5 do
    hl.bind("SUPER+ALT+code:" .. tostring(index + 9), hl.dsp.group.active({ index = index }))
  end
''
