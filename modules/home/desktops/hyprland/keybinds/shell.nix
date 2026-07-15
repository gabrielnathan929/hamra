_: ''
  -- General
  hl.bind("SUPER+CTRL+S",     hl.dsp.exec_cmd(ipc .. " status"))
  hl.bind("SUPER+CTRL+R",     hl.dsp.exec_cmd(ipc .. " config-reload"))

  -- Window Switcher
  hl.bind("ALT+Tab",          hl.dsp.exec_cmd(ipc .. " window-switcher"))
  hl.bind("ALT+SHIFT+Tab",    hl.dsp.exec_cmd(ipc .. " window-switcher close"))

  -- Session
  hl.bind("SUPER+ALT+L",      hl.dsp.exec_cmd(ipc .. " session lock"))
  hl.bind("SUPER+SHIFT+L",    hl.dsp.exec_cmd(ipc .. " session lock-and-suspend"))
  hl.bind("SUPER+CTRL+ALT+L", hl.dsp.exec_cmd(ipc .. " session logout"))
  hl.bind("SUPER+CTRL+ALT+R", hl.dsp.exec_cmd(ipc .. " session reboot"))
  hl.bind("SUPER+CTRL+ALT+S", hl.dsp.exec_cmd(ipc .. " session shutdown"))
''
