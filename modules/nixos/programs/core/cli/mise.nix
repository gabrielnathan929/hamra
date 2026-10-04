{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.mise;
  tools = config.hamra.mise.tools;
  env = config.hamra.mise.env;
  settings = config.hamra.mise.settings;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;

  miseValue = types.oneOf [
    types.str
    types.bool
    (types.listOf types.str)
    (types.attrsOf miseValue)
  ];

  globalConfig =
    lib.optionalAttrs (tools != {}) {inherit tools;}
    // lib.optionalAttrs (env != {}) {inherit env;}
    // lib.optionalAttrs (settings != {}) {inherit settings;};
in {
  options.hamra = {
    programs.core.cli.mise = mkOption {
      type = types.bool;
      default = true;
      description = "Enable mise.";
    };

    mise = {
      tools = mkOption {
        type = types.attrsOf miseValue;
        default = {};
        example = {
          node = "lts";
          python = ["3.12" "3.13"];
          "github:herdrdev/herdr" = "latest";
        };
        description = "Declare mise tools globally (~/.config/mise/config.toml).";
      };

      env = mkOption {
        type = types.attrsOf miseValue;
        default = {};
        example = {
          _.path = ["~/.opencode/bin"];
        };
        description = "Declare mise env globals (~/.config/mise/config.toml).";
      };

      settings = mkOption {
        type = types.attrsOf miseValue;
        default = {};
        example = {
          github_attestations = false;
        };
        description = "Declare mise settings (~/.config/mise/config.toml).";
      };
    };
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.mise];

    home-manager.users.${userName}.programs.mise =
      {
        enable = true;
        enableZshIntegration = true;
      }
      // lib.optionalAttrs (globalConfig != {}) {
        inherit globalConfig;
      };
  };
}
