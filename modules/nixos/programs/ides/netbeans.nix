{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.ides.netbeans;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.ides.netbeans = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Apache NetBeans.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [netbeans]);
}
