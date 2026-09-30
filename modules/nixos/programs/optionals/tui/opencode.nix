{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.opencode;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.opencode = mkOption {
    type = types.bool;
    default = false;
    description = "Enable opencode (AI coding assistant).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [opencode]);
}
