_: ''
  -- Volume
  hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(ipc .. " volume-up"))
  hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(ipc .. " volume-down"))
  hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(ipc .. " volume-mute"))

  -- Microphone
  hl.bind("SUPER+CTRL+SHIFT+UP",   hl.dsp.exec_cmd(ipc .. " mic-volume-up"))
  hl.bind("SUPER+CTRL+SHIFT+DOWN", hl.dsp.exec_cmd(ipc .. " mic-volume-down"))
  hl.bind("SUPER+CTRL+SHIFT+M",    hl.dsp.exec_cmd(ipc .. " mic-mute"))

  -- Brightness
  hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. " brightness-up"))
  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness-down"))

  -- Sleep
  hl.bind("XF86Sleep",             hl.dsp.exec_cmd(ipc .. " session suspend"))

  -- Wi-Fi
  hl.bind("XF86WLAN",              hl.dsp.exec_cmd(ipc .. "wifi-toggle"))
  hl.bind("XF86RFKill",            hl.dsp.exec_cmd(ipc .. "wifi-toggle"))

  -- Night Light
  hl.bind("SUPER+CTRL+N",          hl.dsp.exec_cmd(ipc .. "nightlight-toggle"))

  -- Wireless
  hl.bind("SUPER+CTRL+W",          hl.dsp.exec_cmd(ipc .. "wifi-toggle"))

  -- Bluetooth
  hl.bind("SUPER+CTRL+B",          hl.dsp.exec_cmd(ipc .. "bluetooth-toggle"))

  -- Caffeine
  hl.bind("SUPER+CTRL+C",          hl.dsp.exec_cmd(ipc .. "caffeine-toggle"))

  -- Power Profile
  hl.bind("SUPER+CTRL+P",          hl.dsp.exec_cmd(ipc .. "power-cycle"))

  -- Monitor Power
  hl.bind("SUPER+CTRL+M",          hl.dsp.exec_cmd(ipc .. "dpms-on"))
  hl.bind("SUPER+CTRL+ALT+M",      hl.dsp.exec_cmd(ipc .. "dpms-off"))
''
