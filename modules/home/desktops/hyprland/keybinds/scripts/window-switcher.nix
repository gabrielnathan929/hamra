{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
  leaveSpecial = import ./leave-special.nix {inherit pkgs;};
in
  writeShellScript "hypr-window-switcher" ''
    ${leaveSpecial}
    exec noctalia msg window-switcher hold
  ''
