{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.productivity.obsidian;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.productivity.obsidian = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Obsidian e permitir Electron inseguro.";
  };

  config = mkIf cfg {
    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];

    environment.systemPackages = [pkgs.obsidian];
  };
}
