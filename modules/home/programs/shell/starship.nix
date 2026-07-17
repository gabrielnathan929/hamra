{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.shell.starship;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.shell.starship = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Starship prompt.";
  };

  config.programs.starship = mkIf cfg {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
}
