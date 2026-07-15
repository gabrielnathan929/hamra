{
  config,
  lib,
  ...
}: let
  timezone = config.hamra.timezone;
in {
  options.hamra.timezone = lib.mkOption {
    type = lib.types.str;
    default = "America/Sao_Paulo";
    description = "Fuso horário.";
  };

  config.time.timeZone = lib.mkDefault timezone;
}
