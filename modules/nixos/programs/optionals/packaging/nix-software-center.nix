{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.hamra.programs.optionals.packaging."nix-software-center";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.packaging."nix-software-center" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Nix Software Center (graphical Nix package manager).";
  };

  config.environment.systemPackages = mkIf cfg [
    inputs.nix-software-center.packages.${pkgs.stdenv.system}.nix-software-center
  ];
}
