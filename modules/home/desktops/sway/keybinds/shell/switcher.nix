{pkgs, ...}: let
  altTab = import ../scripts/alt-tab.nix {inherit pkgs;};
in ''
  bindsym Alt+Tab             exec ${altTab} next
  bindsym Alt+Shift+Tab       exec ${altTab} prev
  bindsym $mod+w              exec $ipc window-switcher
''
