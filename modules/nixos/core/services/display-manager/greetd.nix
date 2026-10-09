{
  config,
  lib,
  pkgs,
  ...
}: let
  displayManager = config.hamra.displayManager;
  displays = config.hamra.displays.physical or {} // config.hamra.displays.virtual or {};
  scaleStr = scale: let
    whole = builtins.floor scale;
    trim = s:
      if lib.hasSuffix "0" s
      then trim (lib.removeSuffix "0" s)
      else lib.removeSuffix "." s;
  in
    if whole == scale
    then toString whole
    else trim (toString scale);
  scales = lib.mapAttrsToList (name: cfg: "${name}:${scaleStr cfg.scale}") displays;
in {
  config = lib.mkIf (displayManager.default == "greetd") {
    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        appearance = {
          scheme = "Catppuccin";
          hide_logo = true;
        };
        cursor = {
          theme = "Bibata-Modern-Classic";
          size = 24;
          path = pkgs.bibata-cursors;
        };
        output = lib.optionalAttrs (scales != []) {
          scales = lib.concatStringsSep "; " scales;
        };
      };
    };
  };
}
