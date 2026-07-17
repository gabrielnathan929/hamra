{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.pcsx2;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.pcsx2 = mkOption {
    type = types.bool;
    default = false;
    description = "Enable PCSX2 (PS2 emulator).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [pcsx2]);
}
