{
  config,
  lib,
  env,
  ...
}: let
  terminal = lib.getExe env.terminal;
in ''
  # Scripts
  bindsym $mod+Ctrl+Alt+g         exec ${terminal} -e setup-gpg
  bindsym $mod+Ctrl+Alt+h         exec ${terminal} -e setup-ssh
  bindsym $mod+Alt+f              exec ${terminal} -e flatpak-install
  bindsym $mod+Ctrl+Alt+f         exec ${terminal} -e flatpak-remove
''
