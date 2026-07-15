{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.office;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.office = mkOption {
    type = types.bool;
    default = false;
    description = "Enable LibreOffice.";
  };

  config.home.packages = mkIf cfg (with pkgs; [
    libreoffice-fresh
  ]);
}
