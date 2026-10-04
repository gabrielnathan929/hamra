{keyboard, ...}: ''
  hl.config({
    input = {
      kb_layout = "${keyboard.keymap}",
      kb_variant = "${keyboard.xkbVariant}",
      natural_scroll = false,
      touchpad = {
        natural_scroll = true,
      },
    },
  })
''
