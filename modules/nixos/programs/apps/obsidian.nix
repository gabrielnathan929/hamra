{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.apps.obsidian;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.apps.obsidian = mkOption {
    type = types.bool;
    default = false;
    description = "Habilitar Obsidian e permitir Electron inseguro.";
  };

  config.nixpkgs.config.permittedInsecurePackages = mkIf cfg [
    "electron-39.8.10"
  ];
}
