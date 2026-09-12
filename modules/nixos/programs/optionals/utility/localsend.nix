{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.utility.localsend;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.utility.localsend = mkOption {
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
