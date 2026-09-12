{
  displays,
  lib,
}: let
  primaryMonitor = let
    allPrimary = displays.physical // displays.virtual;
  in
    if allPrimary != {}
    then lib.head (builtins.attrNames allPrimary)
    else "eDP-1";

  # Sway's headless backend auto-names outputs HEADLESS-N (always starts at HEADLESS-1)
  headlessMonitor =
    if (displays.headless or {}) != {}
    then "HEADLESS-1"
    else null;

  # Workspaces 1-5 no monitor primário
  primaryRules = lib.concatStringsSep "\n" (
    lib.map (i: "workspace ${toString i} output ${primaryMonitor}")
    (lib.genList (x: x + 1) 5)
  );

  # Workspaces 6-10 no monitor headless
  headlessRules =
    if headlessMonitor != null
    then
      lib.concatStringsSep "\n" (
        lib.map (i: "workspace ${toString i} output ${headlessMonitor}")
        (let start = 6; in lib.genList (x: x + start) 5)
      )
    else "";
in
  lib.concatStringsSep "\n" (lib.filter (s: s != "") [primaryRules headlessRules])
