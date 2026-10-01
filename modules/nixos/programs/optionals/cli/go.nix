{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.go;
  inherit (lib) mkOption mkIf types;
  user = config.hamra.users.userName;
  goPath = "/home/${user}/go";
in {
  options.hamra.programs.optionals.cli.go = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Golang.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.go];

    environment.sessionVariables = {
      GOPATH = goPath;
      PATH = ["${goPath}/bin"];
    };
  };
}
