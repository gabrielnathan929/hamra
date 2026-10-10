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
    description = "Shortcuts by context, shown by keys via /etc/hamra/keybinds.json.";
  };
}
