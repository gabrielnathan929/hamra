_: ''
  hl.bind("SUPER+CTRL+Z", function()
    local zoom = hl.get_config("cursor.zoom_factor") or 1
    hl.config({ cursor = { zoom_factor = zoom + 1 } })
  end)
  hl.bind("SUPER+CTRL+ALT+Z", function()
    hl.config({ cursor = { zoom_factor = 1 } })
  end)
  hl.bind("SUPER+ALT+mouse_up", function()
    local zoom = hl.get_config("cursor.zoom_factor") or 1
    hl.config({ cursor = { zoom_factor = zoom + 1 } })
  end)
  hl.bind("SUPER+ALT+mouse_down", function()
    hl.config({ cursor = { zoom_factor = 1 } })
  end)
''
