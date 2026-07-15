{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  // Scripts
  Mod+Ctrl+Alt+g           { spawn-sh "${terminal} -e setup-gpg"; }
  Mod+Ctrl+Alt+h           { spawn-sh "${terminal} -e setup-ssh"; }
  Mod+Alt+f                { spawn-sh "${terminal} -e flatpak-install"; }
  Mod+Ctrl+Alt+f           { spawn-sh "${terminal} -e flatpak-remove"; }
''
