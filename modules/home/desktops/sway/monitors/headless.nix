{
  displays,
  lib,
}: let
  headlessDisplays = displays.headless or {};
  firstHeadless = lib.head (builtins.attrValues headlessDisplays);
  firstHeadlessName = lib.head (builtins.attrNames headlessDisplays);
  cfg = firstHeadless;
in
  if headlessDisplays == {}
  then ""
  else ''
    output "${firstHeadlessName}" {
      mode ${cfg.mode}${lib.optionalString (lib.hasInfix "@" cfg.mode) "Hz"}
      position ${lib.replaceStrings ["x"] [" "] cfg.position}
      scale ${toString cfg.scale}
    }
  ''
