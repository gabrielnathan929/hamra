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
    description = "Loose packages installed directly on the system, without a toggle module. Use for quick installs.";
  };

  config.environment.systemPackages = mkIf (config.hamra.packages.extra != []) config.hamra.packages.extra;
}
