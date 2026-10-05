{keyboard, ...}: let
  windowRulesPart = import ./window-rules.nix {};
  blurPart = import ./blur.nix {};
  inputPart = import ./input.nix {inherit keyboard;};
  layoutPart = import ./layout.nix {};
in ''
  ${windowRulesPart}

  ${blurPart}

  ${inputPart}

  ${layoutPart}
''
