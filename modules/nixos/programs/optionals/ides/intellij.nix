{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.intellij;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.intellij = mkOption {
    type = types.bool;
    default = false;
    description = "Enable IntelliJ IDEA Ultimate.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [jetbrains.idea]);
}
