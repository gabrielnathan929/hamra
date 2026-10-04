{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui."keepassxc";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.keepassxc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable KeePassXC.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [keepassxc]);
}
