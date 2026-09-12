{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.communication.discord;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.communication.discord = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Discord (voice, video and text chat).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.discord];
}
