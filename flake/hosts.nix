{
  lib,
  mkHost,
  ...
}: let
  inherit (builtins) attrNames filter listToAttrs map readDir;
  entries = readDir ../hosts;
  isHost = name: entries.${name} == "directory" && !lib.hasPrefix "." name;
  hostNames = filter isHost (attrNames entries);
in
  listToAttrs (map (name: {
      inherit name;
      value = mkHost name;
    })
    hostNames)
