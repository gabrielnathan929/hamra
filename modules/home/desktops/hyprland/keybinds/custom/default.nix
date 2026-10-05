{
  lib,
  env,
  ...
}: let
  envsPart = import ./envs.nix {inherit lib env;};
  windowsPart = import ./windows.nix {};
  focusPart = import ./focus.nix {};
  workspacesPart = import ./workspaces.nix {};
  mousePart = import ./mouse.nix {};
  zoomPart = import ./zoom.nix {};
  scriptsPart = import ./scripts.nix {inherit lib env;};
  layoutsPart = import ./layouts.nix {};
in ''
  ${envsPart}
  ${windowsPart}
  ${focusPart}
  ${workspacesPart}
  ${mousePart}
  ${zoomPart}
  ${scriptsPart}
  ${layoutsPart}
''
