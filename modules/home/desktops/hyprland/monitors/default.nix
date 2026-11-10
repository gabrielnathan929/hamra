{
  displays,
  lib,
}: let
  virtualPart = import ./virtual.nix {inherit displays lib;};
  physicalPart = import ./physical.nix {inherit displays lib;};
  headlessPart = import ./headless.nix {inherit displays lib;};
  workspacesPart = import ./workspaces.nix {inherit displays lib;};

  allMonitors = lib.concatStringsSep "\n\n" (
    lib.filter (s: s != "") [
      virtualPart
      physicalPart
      headlessPart
    ]
  );
in ''
    -- Monitors
  ${allMonitors}

    -- Persistent workspaces
  ${workspacesPart}
''
