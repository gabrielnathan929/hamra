_: ''
  -- Noctalia v5
  hl.layer_rule({
    name          = "noctalia",
    match         = {
      namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
    },
    no_anim       = true,
    ignore_alpha  = 0.5,
    blur          = true,
    blur_popups   = true,
  })
''
