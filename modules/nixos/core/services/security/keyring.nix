{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.services.keyring;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.services.keyring = mkOption {
    type = types.bool;
    default = true;
    description = "Enable GNOME Keyring and Seahorse.";
  };

  config = mkIf cfg {
    services.gnome.gnome-keyring.enable = true;
    environment.systemPackages = [pkgs.seahorse];
  };
}
