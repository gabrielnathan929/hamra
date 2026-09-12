{keyboard, ...}: ''
  input "type:touchpad" {
    tap enabled
    natural_scroll enabled
  }

  input "type:mouse" {
    natural_scroll disabled
  }

  input "*" {
    xkb_layout "${keyboard.keymap}"
    xkb_variant "${keyboard.xkbVariant}"
  }

  input "1575:1:QEMU_QEMU_USB_Tablet" {
    map_to_output Virtual-1
  }
''
