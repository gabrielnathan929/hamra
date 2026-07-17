{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.netbeans;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.netbeans = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Apache NetBeans.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [netbeans]);
}
