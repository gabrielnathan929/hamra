{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.hamra.keybinds = mkOption {
    type = types.attrsOf (types.listOf (types.attrsOf types.str));
    default = {};
    example = {
      tmux = [
        {
          key = "Prefix + c";
          action = "Create window";
        }
      ];
    };
    description = "Atalhos por contexto, exibidos pelo hamra-keybinds via /etc/hamra/keybinds.json.";
  };
}
