{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.jdk;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.jdk = mkOption {
    type = types.bool;
    default = false;
    description = "Enable OpenJDK 17 (Java).";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [jdk17];

    environment.sessionVariables.JAVA_HOME = "${pkgs.jdk17}";
  };
}
