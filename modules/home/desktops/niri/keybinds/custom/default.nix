{
  config,
  lib,
  env,
  pkgs,
  ...
}: let
  envsPart = import ./envs.nix {inherit config lib env;};
  windowsPart = import ./windows.nix {};
  columnPart = import ./column.nix {};
  focusPart = import ./focus.nix {};
  workspacesPart = import ./workspaces.nix {inherit pkgs;};
  mousePart = import ./mouse.nix {};
  scriptsPart = import ./scripts.nix {inherit config lib env;};
in ''
  ${envsPart}
  ${windowsPart}
  ${columnPart}
  ${focusPart}
  ${workspacesPart}
  ${mousePart}
  ${scriptsPart}
''
