{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.nodejs;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.nodejs = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Node.js.";
  };

  config.home.packages = mkIf cfg [pkgs.nodejs];
}
