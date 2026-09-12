{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
  browser = lib.getExe env.browser;
  filemanager = lib.getExe env.filemanager;
  editor = lib.getExe env.editor;
in ''
  -- Envs
  hl.bind(
    "SUPER+Return",
    hl.dsp.exec_cmd("${terminal}")
  )
  hl.bind(
    "SUPER+E",
    hl.dsp.exec_cmd("${filemanager}")
  )
  hl.bind(
    "SUPER+B",
    hl.dsp.exec_cmd("${browser}")
  )
  hl.bind(
    "SUPER+SHIFT+B",
    hl.dsp.exec_cmd("${browser} --private-window")
  )
  hl.bind(
    "SUPER+SHIFT+N",
    hl.dsp.exec_cmd("${terminal} -e ${editor}")
  )

  -- OCR
  hl.bind(
    "SUPER+CTRL+Print",
    hl.dsp.exec_cmd("ocr-screenshot")
  )
  -- Btop
  hl.bind(
    "SUPER+ALT+T",
    hl.dsp.exec_cmd("${terminal} -e btop")
  )

  -- Lazydocker
  hl.bind(
    "SUPER+SHIFT+D",
    hl.dsp.exec_cmd("${terminal} -e lazydocker")
  )

  -- Lazygit
  hl.bind(
    "SUPER+SHIFT+G",
    hl.dsp.exec_cmd("${terminal} -e lazygit")
  )
''
