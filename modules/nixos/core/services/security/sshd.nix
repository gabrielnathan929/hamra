{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.services.sshd;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.services.sshd = mkOption {
    type = types.bool;
    default = true;
    description = "Enable SSH daemon.";
  };

  config.services.openssh = mkIf cfg {
    enable = true;
  };
}
