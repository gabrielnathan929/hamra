{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.services.polkit;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.services.polkit = mkOption {
    type = types.bool;
    default = true;
    description = "Enable PolKit and udisks2.";
  };

  config = mkIf cfg {
    security.polkit.enable = true;
    services.udisks2.enable = true;
  };
}
