_: ''
  hl.bind("SUPER+SHIFT+Space", hl.dsp.exec_cmd(ipc .. " bar-toggle"))
  hl.bind("SUPER+Space",       hl.dsp.exec_cmd(ipc .. " dock-toggle"))
  hl.bind("SUPER+ALT+Space",   hl.dsp.exec_cmd(ipc .. " dock-reload"))

  hl.bind("SUPER+Escape",      hl.dsp.exec_cmd(ipc .. " panel-toggle session"))
  hl.bind("SUPER+CTRL+V",      hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"))
  hl.bind("SUPER+CTRL+Space",  hl.dsp.exec_cmd(ipc .. " panel-toggle wallpaper"))
  hl.bind("SUPER+comma",       hl.dsp.exec_cmd(ipc .. " settings-toggle"))

  hl.bind("SUPER+D",           hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))

  -- Desktop Widgets
  hl.bind("SUPER+W",           hl.dsp.exec_cmd(ipc .. " desktop-widgets-toggle"))
  hl.bind("SUPER+SHIFT+W",     hl.dsp.exec_cmd(ipc .. " desktop-widgets-toggle-edit"))

  -- Lockscreen Widgets
  hl.bind("SUPER+SHIFT+CTRL+L",     hl.dsp.exec_cmd(ipc .. " lockscreen-widgets-toggle-edit"))

  -- Noctalia Plugins
  hl.bind("SUPER+CTRL+SHIFT+B", hl.dsp.exec_cmd(ipc .. " plugin noctalia/bongocat:cat focused toggle"))
  hl.bind("SUPER+CTRL+SHIFT+W", hl.dsp.exec_cmd(ipc .. " panel-toggle noctalia/wallhaven:browser"))
  hl.bind("SUPER+CTRL+SHIFT+V", hl.dsp.exec_cmd(ipc .. " panel-toggle noctalia/mpvpaper:picker"))
''
