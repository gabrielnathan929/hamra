_: let
  audioPart = import ./audio.nix {};
  displayPart = import ./display.nix {};
  togglesPart = import ./toggles.nix {};
in ''
  ${audioPart}
  ${displayPart}
  ${togglesPart}
''
