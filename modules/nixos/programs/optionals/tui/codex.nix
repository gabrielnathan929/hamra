{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.codex;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.codex = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Codex CLI (OpenAI coding agent).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [codex]);
}
