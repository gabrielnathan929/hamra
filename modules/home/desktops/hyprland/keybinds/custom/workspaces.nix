_: ''
  local function leave_special()
    if hl.get_active_special_workspace() ~= nil then
      hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
    end
  end

  local function ws_monitor_name(ws)
    if ws == nil or ws.monitor == nil then
      return nil
    end
    return ws.monitor.name
  end

  local function workspace_cycle(direction)
    leave_special()

    local active = hl.get_active_workspace()
    local current = active and active.id or nil
    local active_monitor = ws_monitor_name(active)
    local candidates = {}

    for _, ws in ipairs(hl.get_workspaces()) do
      if ws.id ~= nil and not ws.special and ws.windows > 0 and ws.id ~= current then
        local ws_monitor = ws_monitor_name(ws)
        if active_monitor == nil or ws_monitor == nil or ws_monitor == active_monitor then
          candidates[#candidates + 1] = ws.id
        end
      end
    end

    if #candidates == 0 then
      return
    end

    table.sort(candidates)

    local pick = nil

    if direction == "prev" then
      for index = #candidates, 1, -1 do
        if current == nil or candidates[index] < current then
          pick = candidates[index]
          break
        end
      end
      if pick == nil then
        pick = candidates[#candidates]
      end
    else
      for _, id in ipairs(candidates) do
        if current == nil or id > current then
          pick = id
          break
        end
      end
      if pick == nil then
        pick = candidates[1]
      end
    end

    hl.dispatch(hl.dsp.focus({ workspace = tostring(pick) }))
  end

  local function layout_toggle()
    local active = hl.get_active_workspace()
    if active == nil or active.id == nil then
      return
    end

    local new = "dwindle"
    if active.tiled_layout == "dwindle" then
      new = "scrolling"
    end

    local state_dir = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state") .. "/hamra/workspace-layouts"
    os.execute("mkdir -p '" .. state_dir .. "'")

    local file = io.open(state_dir .. "/" .. tostring(active.id), "w")
    if file then
      file:write(new)
      file:close()
    end

    hl.workspace_rule({ workspace = tostring(active.id), layout = new })
  end

  hl.bind("SUPER+TAB", function() workspace_cycle("next") end)
  hl.bind("SUPER+SHIFT+TAB", function() workspace_cycle("prev") end)
  hl.bind(
    "SUPER+CTRL+TAB",
    hl.dsp.focus({ workspace = "previous" })
  )
  hl.bind("SUPER+L", layout_toggle)

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
