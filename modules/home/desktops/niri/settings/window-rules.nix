_: ''
  window-rule {
    geometry-corner-radius 20
    clip-to-geometry true
  }

  window-rule {
    match app-id="console"
    open-floating true
    default-column-width {
      fixed 1100
    }
    default-window-height {
      fixed 700
    }
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

  window-rule {
    match title="^WebcamOverlay$"
    open-floating true
    default-column-width {
      fixed 420
    }
    default-window-height {
      fixed 236
    }
    default-floating-position x=32 y=32 relative-to="bottom-right"
  }

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
