{
  config,
  lib,
  ...
}: let
  locale = config.hamra.locale;
  localeFields = [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ];
in {
  options.hamra.locale = lib.mkOption {
    type = lib.types.str;
    default = "en_US.UTF-8";
    description = "Locale padrão.";
  };

  config.i18n = {
    defaultLocale = lib.mkDefault locale;
    extraLocaleSettings = lib.genAttrs localeFields (_: lib.mkDefault locale);
  };
}
