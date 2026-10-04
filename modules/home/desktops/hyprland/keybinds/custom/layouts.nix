_: ''
  local state_dir = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state") .. "/hamra/workspace-layouts"
  local pipe = io.popen("ls " .. state_dir .. " 2>/dev/null")
  if pipe then
    local entries = {}
    for entry in pipe:lines() do
      entries[#entries + 1] = entry
    end
    pipe:close()
    for _, entry in ipairs(entries) do
      local file = io.open(state_dir .. "/" .. entry, "r")
      if file then
        local layout = file:read("*l")
        file:close()
        if layout == "dwindle" or layout == "scrolling" then
          hl.workspace_rule({ workspace = entry, layout = layout })
        end
      end
    end
  end
''
