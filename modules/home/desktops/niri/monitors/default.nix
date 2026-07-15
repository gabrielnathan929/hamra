{
  displays,
  lib,
}: let
  toNiriPosition = pos: let
    parts = lib.splitString "x" pos;
  in "x=${lib.elemAt parts 0} y=${lib.elemAt parts 1}";

  virtualPart = import ./virtual.nix {inherit displays lib toNiriPosition;};
  physicalPart = import ./physical.nix {inherit displays lib toNiriPosition;};
  headlessPart = import ./headless.nix {inherit displays lib toNiriPosition;};

  allOutputs = lib.concatStringsSep "\n\n" (
    lib.filter (s: s != "") [
      virtualPart
      physicalPart
      headlessPart
    ]
  );
in ''
      // Monitores
  ${allOutputs}

      // Custom
''
