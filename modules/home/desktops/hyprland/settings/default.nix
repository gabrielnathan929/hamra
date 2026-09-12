{keyboard}: let
  generalPart = import ./general.nix {};
  decorationPart = import ./decoration.nix {};
  animationsPart = import ./animations.nix {};
  inputPart = import ./input.nix {inherit keyboard;};
  miscPart = import ./misc.nix {};
in ''
  -- Noctalia v5
  ${generalPart}

  ${decorationPart}

  ${animationsPart}

  ${inputPart}

  -- Custom
  ${miscPart}
''
