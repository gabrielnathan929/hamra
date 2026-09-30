{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.tui.opencode;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.tui.opencode = mkOption {
    type = types.bool;
    default = false;
    description = "Enable opencode (AI coding assistant).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [opencode]);
}
