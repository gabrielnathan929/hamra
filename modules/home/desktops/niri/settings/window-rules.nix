_: ''
  window-rule {
    geometry-corner-radius 20
    clip-to-geometry true
  }

  window-rule {
    match app-id="dev.noctalia.Noctalia.Settings"
    open-floating true
    default-column-width {
      fixed 1080
    }
    default-window-height {
      fixed 920
    }
  }

  // Niri blur (26.04+)
  window-rule {
    background-effect {
      blur true
      xray false
    }
  }

  layer-rule {
    match namespace="^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"
    background-effect {
      xray false
    }
  }
''
