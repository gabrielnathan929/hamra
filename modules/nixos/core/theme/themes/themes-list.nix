let
  inherit (builtins) readDir attrNames removeAttrs sort lessThan;

  themeEntries = readDir ./.;
  themeNames = sort lessThan (
    attrNames (removeAttrs themeEntries [
      "default.nix"
      "theme.nix"
      "themes-list.nix"
    ])
  );
in
  themeNames
