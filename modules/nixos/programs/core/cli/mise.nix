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

  tomlFormat = pkgs.formats.toml {};

  userName = config.hamra.users.userName;
  userHome = config.users.users.${userName}.home;

  toolsHash = builtins.hashString "sha256" (builtins.toJSON tools);

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
        inherit (tomlFormat) type;
        default = {};
        example = {
          node = "lts";
          python = ["3.12" "3.13"];
          "github:herdrdev/herdr" = "latest";
        };
        description = ''
          Declare mise tools globally (~/.config/mise/config.toml).
          hamra-mise-install installs them on activation.
        '';
      };

      env = mkOption {
        inherit (tomlFormat) type;
        default = {};
        example = {
          "_.path" = ["~/bin"];
        };
        description = ''
          Declare mise environment configuration globally
          (~/.config/mise/config.toml).
        '';
      };

      settings = mkOption {
        inherit (tomlFormat) type;
        default = {};
        example = {
          github_attestations = false;

          python = {
            compile = false;
          };
        };
        description = ''
          Declare mise settings globally (~/.config/mise/config.toml).
        '';
      };
    };
  };

  config = mkIf cfg {
    environment.systemPackages = [
      pkgs.mise
    ];

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

      wants = [
        "network-online.target"
        "home-manager-${userName}.service"
      ];

      after = [
        "network-online.target"
        "home-manager-${userName}.service"
      ];

      restartTriggers = [toolsHash];

      path = [pkgs.bash pkgs.nodejs];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        User = userName;

        Environment = ["HOME=${userHome}"];

        ExecStart = "${pkgs.mise}/bin/mise install";
      };
    };
  };
}
