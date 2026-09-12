_: ''
  // Noctalia v5
  debug {
    honor-xdg-activation-with-invalid-serial
  }

  layer-rule {
    match namespace="^noctalia-backdrop"
    place-within-backdrop true
  }

  spawn-at-startup "noctalia"
''
