{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.mise;
  tools = config.hamra.mise.tools;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.core.cli.mise = mkOption {
    type = types.bool;
    default = true;
    description = "Enable mise.";
  };

  options.hamra.mise.tools = mkOption {
    type = types.attrsOf (types.oneOf [types.str (types.listOf types.str)]);
    default = {};
    example = {
      node = "lts";
      python = ["3.12" "3.13"];
    };
    description = "Declare mise tools globally (~/.config/mise/config.toml).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.mise];

    home-manager.users.${userName}.programs.mise =
      {
        enable = true;
        enableZshIntegration = true;
      }
      // lib.optionalAttrs (tools != {}) {
        globalConfig.settings.tools = tools;
      };
  };
}
