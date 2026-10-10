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

  headlessMonitor =
    if (displays.headless or {}) != {}
    then lib.head (builtins.attrNames (displays.headless or {}))
    else null;

  primaryRules = lib.concatStringsSep "\n" (
    lib.map (i: "workspace ${toString i} output ${primaryMonitor}")
    (lib.genList (x: x + 1) 5)
  );

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
