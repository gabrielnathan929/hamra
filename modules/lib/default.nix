{lib}: {
  scanPaths = dir: let
    inherit (builtins) readDir attrNames sort lessThan filter;
    entries = readDir dir;
    keep = n:
      entries.${n}
      == "directory"
      || (entries.${n} == "regular" && lib.hasSuffix ".nix" n && n != "default.nix");
  in
    map (n: dir + "/${n}") (sort lessThan (filter keep (attrNames entries)));
}
