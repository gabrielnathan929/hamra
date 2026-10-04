{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.intellij;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.intellij = mkOption {
    type = types.bool;
    default = false;
    description = "Enable IntelliJ IDEA Ultimate.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [jetbrains.idea]);
}
