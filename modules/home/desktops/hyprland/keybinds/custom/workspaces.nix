{pkgs, ...}: let
  next = import ../scripts/workspace-next.nix {};
  prev = import ../scripts/workspace-prev.nix {};
  layoutToggle = import ../scripts/layout-toggle.nix {inherit pkgs;};
in ''
  hl.bind("SUPER+TAB", hl.dsp.exec_cmd([[
    ${next}
  ]]))
  hl.bind("SUPER+SHIFT+TAB", hl.dsp.exec_cmd([[
    ${prev}
  ]]))
  hl.bind(
    "SUPER+CTRL+TAB",
    hl.dsp.focus({ workspace = "previous" })
  )
  hl.bind(
    "SUPER+L",
    hl.dsp.exec_cmd("${layoutToggle}")
  )

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

  hl.bind(
    "SUPER+S",
    hl.dsp.workspace.toggle_special("scratchpad")
  )
  hl.bind(
    "SUPER+ALT+S",
    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })
  )

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

  for index = 1, 5 do
    hl.bind("SUPER+ALT+code:" .. tostring(index + 9), hl.dsp.group.active({ index = index }))
  end
''
