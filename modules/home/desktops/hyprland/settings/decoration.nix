_: ''
  hl.config({
    decoration = {
      rounding       = 20,
      rounding_power = 2,
      active_opacity   = 1.0,
      inactive_opacity = 1.0,
      shadow = {
        enabled      = true,
        range        = 4,
        render_power = 3,
        color        = 0xee1a1a1a,
      },
      blur = {
        enabled  = true,
        size     = 3,
        passes   = 1,
        vibrancy = 0.1696,
      },
    },

    group = {
      groupbar = {
        font_size           = 10,
        height              = 18,
        render_titles       = true,
        font_weight_active   = "bold",
        font_weight_inactive = "normal",
        text_color           = 0xffffffff,
        text_color_inactive  = 0xff888888,
      },
    },
  })
''
