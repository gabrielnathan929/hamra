{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.apps.localsend;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.apps.localsend = mkOption {
    type = types.bool;
    default = false;
    description = "Enable LocalSend file sharing.";
  };

  config.home.packages = mkIf cfg [
    (pkgs.writeShellScriptBin "localsend" ''
      exec ${pkgs.localsend}/bin/localsend_app "$@"
    '')
    pkgs.localsend
  ];
}
