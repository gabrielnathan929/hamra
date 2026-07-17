{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.productivity.office;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.productivity.office = mkOption {
    type = types.bool;
    default = false;
    description = "Enable LibreOffice.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [
    libreoffice-fresh
  ]);
}
