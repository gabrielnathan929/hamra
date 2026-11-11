_: ''
  hl.window_rule({
    name = "console-float",
    match = { class = "console" },
    float = true,
    size = "1100 700",
    center = true,
  })

  hl.window_rule({
    name = "webcam-overlay",
    match = { title = "^(WebcamOverlay)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = { "monitor_w*0.26", "monitor_h*0.26" },
    move = { "(monitor_w*0.72)", "(monitor_h*0.71)" },
  })
''
