_: ''
  local zoom_get = function()
    return hl.get_config("cursor.zoom_factor") or 1
  end
  local zoom_set = function(v)
    hl.config({ cursor = { zoom_factor = math.max(v, 1) } })
  end

  hl.bind("SUPER+CTRL+Z", function()
    zoom_set(zoom_get() + 1)
  end)
  hl.bind("SUPER+CTRL+ALT+Z", function()
    zoom_set(1)
  end)
  hl.bind("SUPER+ALT+mouse_up", function()
    zoom_set(zoom_get() - 1)
  end)
  hl.bind("SUPER+ALT+mouse_down", function()
    zoom_set(zoom_get() + 1)
  end)
''
