{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.ripgrep;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.ripgrep = mkOption {
    type = types.bool;
    default = false;
    description = "Enable ripgrep.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.ripgrep];
}
