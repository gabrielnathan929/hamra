{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.hamra.programs.services.btop;
in {
  options.hamra.programs.services.btop = mkOption {
    type = types.bool;
    default = false;
    description = "Enable btop resource monitor (com suporte a GPU via cap_perfmon).";
  };

  config = mkIf cfg {
    security.wrappers.btop = {
      owner = "root";
      group = "root";
      capabilities = "cap_perfmon=+ep";
      source = "${pkgs.btop}/bin/btop";
    };
  };
}
