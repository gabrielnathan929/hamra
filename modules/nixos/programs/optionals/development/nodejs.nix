{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.development.nodejs;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.development.nodejs = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Node.js.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.nodejs];
}
