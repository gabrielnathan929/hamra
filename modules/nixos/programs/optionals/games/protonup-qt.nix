{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games."protonup-qt";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games."protonup-qt" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable ProtonUp-Qt (GUI that downloads and updates Proton builds into compatibilitytools.d, read by umu-launcher, Hydra and Steam).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [protonup-qt]);
}
