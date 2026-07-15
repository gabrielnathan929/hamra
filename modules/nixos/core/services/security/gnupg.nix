{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.services.gnupg;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.services.gnupg = mkOption {
    type = types.bool;
    default = true;
    description = "Enable GnuPG agent with SSH support.";
  };

  config = mkIf cfg {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    environment.systemPackages = [pkgs.pinentry-gnome3];
  };
}
