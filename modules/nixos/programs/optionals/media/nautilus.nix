{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.nautilus;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.media.nautilus = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Nautilus.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [nautilus]);
}
