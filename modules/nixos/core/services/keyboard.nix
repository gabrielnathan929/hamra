{
  config,
  lib,
  ...
}: let
  keyboard = config.hamra.keyboard;
in {
  options.hamra.keyboard = {
    keymap = lib.mkOption {
      type = lib.types.str;
      default = "br";
      description = "Keyboard layout (e.g. us, br).";
    };
    xkbVariant = lib.mkOption {
      type = lib.types.str;
      default = "abnt2";
      description = "Layout variant (e.g. intl, dvorak, abnt2).";
    };
  };

  config.services.xserver.xkb = {
    layout = lib.mkDefault keyboard.keymap;
    variant = lib.mkDefault keyboard.xkbVariant;
  };
}
