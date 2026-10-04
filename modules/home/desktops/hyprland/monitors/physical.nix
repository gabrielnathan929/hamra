{
  displays,
  lib,
}: let
  cmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: cfg: ''
      hl.monitor({
          output            = "${name}",
          mode              = "${cfg.mode}",
          position          = "${cfg.position}",
          scale             = ${toString cfg.scale},
          })'')
    displays.physical
  );
in
  cmds
