{
  displays,
  lib,
}: let
  physicalMonitor = let
    allPhysical = displays.physical // displays.virtual;
  in
    if allPhysical != {}
    then lib.head (builtins.attrNames allPhysical)
    else "eDP-1";

  headlessMonitor = let
    allHeadless = displays.headless or {};
  in
    if allHeadless != {}
    then lib.head (builtins.attrNames allHeadless)
    else null;

  # Workspaces 1-5 no monitor fisico
  physicalRules = lib.concatStringsSep "\n" (
    lib.map (i: ''
      hl.workspace_rule({ workspace = "${toString i}", monitor = "${physicalMonitor}", persistent = true })'')
    (lib.genList (x: x + 1) 5)
  );

  # Workspaces 6-10 no monitor headless
  headlessRules =
    if headlessMonitor != null
    then
      lib.concatStringsSep "\n" (
        lib.map (i: ''
          hl.workspace_rule({ workspace = "${toString i}", monitor = "${headlessMonitor}", persistent = true })'')
        (let start = 6; in lib.genList (x: x + start) 5)
      )
    else "";
in
  lib.concatStringsSep "\n" (lib.filter (s: s != "") [physicalRules headlessRules])
