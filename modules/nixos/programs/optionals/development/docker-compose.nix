{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.development."docker-compose";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.development."docker-compose" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Docker Compose.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.docker-compose];
}
