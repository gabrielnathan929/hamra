{mkHost, ...}: let
  inherit (builtins) attrNames filter listToAttrs map readDir;
  entries = readDir ../hosts;
  hostNames = filter (name: entries.${name} == "directory") (attrNames entries);
in
  listToAttrs (map (name: {
      inherit name;
      value = mkHost name;
    })
    hostNames)
