{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.tui.btop;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.tui.btop = mkOption {
    type = types.bool;
    default = true;
    description = "Enable btop resource monitor with GPU support (cap_perfmon).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.btop];

    security.wrappers.btop = {
      owner = "root";
      group = "root";
      capabilities = "cap_perfmon=+ep";
      source = "${pkgs.btop}/bin/btop";
    };
  };
}
