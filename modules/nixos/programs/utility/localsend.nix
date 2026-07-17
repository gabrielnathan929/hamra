{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.utility.localsend;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.utility.localsend = mkOption {
    type = types.bool;
    default = false;
    description = "Enable LocalSend file sharing.";
  };

  config.environment.systemPackages = mkIf cfg [
    (pkgs.writeShellScriptBin "localsend" ''
      exec ${pkgs.localsend}/bin/localsend_app "$@"
    '')
    pkgs.localsend
  ];
}
