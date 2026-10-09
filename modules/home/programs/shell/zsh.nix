{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.shell.zsh;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.shell.zsh = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Zsh configuration.";
  };

  config = {
    programs.zoxide = mkIf cfg {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      options = ["--cmd cd"];
    };

    programs.zsh = mkIf cfg {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        z = "cd";
        zi = "cdi";
      };
      history = {
        size = 10000;
        path = "$HOME/.zsh_history";
        ignoreAllDups = true;
        ignorePatterns = [
          "rm *"
          "pkill *"
          "cp *"
        ];
      };
    };
  };
}
