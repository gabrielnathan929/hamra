{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.development.jdk;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.development.jdk = mkOption {
    type = types.bool;
    default = false;
    description = "Enable OpenJDK 17 (Java).";
  };

  config = lib.mkMerge [
    (mkIf cfg {
      environment.systemPackages = with pkgs; [jdk17];
    })
    (mkIf cfg {
      environment.sessionVariables.JAVA_HOME = "${pkgs.jdk17}";
    })
  ];
}
