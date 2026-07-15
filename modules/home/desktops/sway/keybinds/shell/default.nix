_: let
  generalPart = import ./general.nix {};
  switcherPart = import ./switcher.nix {};
  sessionPart = import ./session.nix {};
in ''
  ${generalPart}
  ${switcherPart}
  ${sessionPart}
''
