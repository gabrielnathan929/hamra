# Lista de temas disponíveis, derivada dinamicamente do diretório themes/.
# Arquivos não são temas (default.nix, theme.nix, themes-list.nix) são excluídos.
# Esta é a ÚNICA fonte da verdade para a lista de temas.
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
