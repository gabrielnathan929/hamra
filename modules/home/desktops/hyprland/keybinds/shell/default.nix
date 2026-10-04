{pkgs, ...}: let
  generalPart = import ./general.nix {};
  switcherPart = import ./switcher.nix {inherit pkgs;};
  sessionPart = import ./session.nix {};
in ''
  ${generalPart}
  ${switcherPart}
  ${sessionPart}
''
