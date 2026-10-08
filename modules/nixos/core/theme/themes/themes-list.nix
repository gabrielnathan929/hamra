# Available themes, derived dynamically from the themes/ directory.
# Non-theme files (default.nix, theme.nix, themes-list.nix) are excluded.
# This is the ONLY source of truth for the theme list.
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
