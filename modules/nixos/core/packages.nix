{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.packages.extra = mkOption {
    type = types.listOf types.package;
    default = [];
    description = "Pacotes avulsos instalados direto no sistema, sem módulo toggle. Use para instalações rápidas.";
  };

  config.environment.systemPackages = mkIf (config.hamra.packages.extra != []) config.hamra.packages.extra;
}
