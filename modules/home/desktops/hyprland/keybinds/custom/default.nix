{
  config,
  lib,
  env,
  ...
}: let
  envsPart = import ./envs.nix {inherit config lib env;};
  windowsPart = import ./windows.nix {};
  focusPart = import ./focus.nix {};
  workspacesPart = import ./workspaces.nix {};
  mousePart = import ./mouse.nix {};
  scriptsPart = import ./scripts.nix {inherit config lib env;};
in ''
  ${envsPart}
  ${windowsPart}
  ${focusPart}
  ${workspacesPart}
  ${mousePart}
  ${scriptsPart}
''
