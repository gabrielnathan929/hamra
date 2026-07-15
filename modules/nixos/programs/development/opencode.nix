{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.opencode;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.opencode = mkOption {
    type = types.bool;
    default = false;
    description = "Enable opencode (AI coding assistant).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [opencode]);
}
