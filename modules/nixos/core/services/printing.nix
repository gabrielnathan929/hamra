{
  config,
  lib,
  ...
}: let
  isEnabled = config.hamra.printing;
in {
  options.hamra.printing = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Habilitar suporte a impressão.";
  };

  config = lib.mkIf isEnabled {
    services.printing.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
