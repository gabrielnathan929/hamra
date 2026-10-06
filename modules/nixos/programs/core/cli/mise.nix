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
  userHome = config.users.users.${userName}.home;
  toolsHash = builtins.hashString "sha256" (builtins.toJSON tools);

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
        description = "Declare mise tools globally (~/.config/mise/config.toml); hamra-mise-install installs them on activation.";
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

    systemd.services.hamra-mise-install = mkIf (tools != {}) {
      description = "Install declared mise tools (hamra.mise.tools)";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = userName;
        Environment = [
          "HOME=${userHome}"
          "HAMRA_MISE_TOOLS_HASH=${toolsHash}"
        ];
        ExecStart = "${pkgs.mise}/bin/mise install";
      };
    };
  };
}
