{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.mise;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.core.cli.mise = mkOption {
    type = types.bool;
    default = true;
    description = "Enable mise.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.mise];

    home-manager.users.${userName}.programs.mise = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
