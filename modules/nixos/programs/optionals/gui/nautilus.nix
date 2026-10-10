{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.nautilus;
  inherit (lib) mkOption mkIf types;
  nautilusExtensions = pkgs.symlinkJoin {
    name = "nautilus-extensions";
    paths = with pkgs; [
      nautilus
      file-roller
    ];
  };
in {
  options.hamra.programs.optionals.gui.nautilus = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Nautilus.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [
      nautilus
      file-roller
    ];

    environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${nautilusExtensions}/lib/nautilus/extensions-4";
  };
}
