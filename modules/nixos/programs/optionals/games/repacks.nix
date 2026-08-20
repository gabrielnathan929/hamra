{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.repacks;
  inherit (lib) mkOption mkIf types;

  script = name: pkgs.writeScriptBin name (builtins.readFile ../../../../../scripts/repacks/${name}.sh);

  repack-scripts = [
    (script "pack-repack")
    (script "restore-repack")
    (script "verify-repack")
    (script "repair-zip")
  ];

  repack-tools = with pkgs; [
    par2cmdline
    unzip
    zip
    rclone
  ];
in {
  options.hamra.programs.optionals.games.repacks = mkOption {
    type = types.bool;
    default = false;
    description = "Enable DODI repack backup/restore tools (par2 + checksum + rclone).";
  };

  config.environment.systemPackages = mkIf cfg (repack-tools ++ repack-scripts);
}
