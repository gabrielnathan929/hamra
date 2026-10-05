_: ''
  local function window_switcher()
    leave_special()
    hl.exec_cmd("noctalia msg window-switcher hold")
  end

  hl.bind("ALT+TAB", window_switcher)
  hl.bind("ALT+SHIFT+TAB", window_switcher)
  hl.bind("SUPER+W", window_switcher)
''
