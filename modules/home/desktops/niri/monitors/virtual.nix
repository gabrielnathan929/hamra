{
  displays,
  lib,
  toNiriPosition,
}: let
  cmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: cfg: ''
      output "${name}" {
          mode "${cfg.mode}"
          position ${toNiriPosition cfg.position}
          scale ${toString cfg.scale}
      }'')
    displays.virtual
  );
in
  cmds
