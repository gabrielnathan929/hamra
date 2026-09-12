{keyboard, ...}: ''
  input {
    keyboard {
      xkb {
        layout "${keyboard.keymap}"
        variant "${keyboard.xkbVariant}"
      }
    }
    touchpad {
      tap
      natural-scroll
    }
    cursor-theme "Bibata-Modern-Classic"
    cursor-size 24
  }
''
