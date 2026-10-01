{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli."trash-cli";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli."trash-cli" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable trash-cli.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.trash-cli];
}
