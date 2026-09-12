_: ''
  -- Notifications
  hl.bind("SUPER+N",       hl.dsp.exec_cmd(ipc .. " notification-dnd-toggle"))

  -- Clipboard
  hl.bind("SUPER+CTRL+X", hl.dsp.exec_cmd(ipc .. " clipboard-clear"))

  -- Media
  hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. " media previous"))
  hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. " media next"))
  hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. " media play"))
  hl.bind("XF86AudioStop", hl.dsp.exec_cmd(ipc .. " media stop"))

  -- Wallpaper
  hl.bind("SUPER+R",       hl.dsp.exec_cmd(ipc .. " wallpaper-random"))

  -- Theme
  hl.bind("SUPER+T",       hl.dsp.exec_cmd(ipc .. " theme-mode-get"))

  -- Screenshots
  hl.bind("Print",          hl.dsp.exec_cmd(ipc .. " screenshot-fullscreen"))
  hl.bind("SUPER+SHIFT+S",  hl.dsp.exec_cmd(ipc .. " screenshot-region"))
''
