{
  displays,
  lib,
}: let
  cmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: cfg: ''
      output "${name}" {
        mode ${cfg.mode}${lib.optionalString (lib.hasInfix "@" cfg.mode) "Hz"}
        position ${lib.replaceStrings ["x"] [" "] cfg.position}
        scale ${toString cfg.scale}
      }'')
    displays.virtual
  );
in
  cmds
