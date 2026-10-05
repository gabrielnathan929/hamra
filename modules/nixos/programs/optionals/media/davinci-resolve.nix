{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media."davinci-resolve";
  gpu = config.hamra.hardware.gpu;
  inherit (lib) mkIf mkOption types;
in {
  options.hamra.programs.optionals.media."davinci-resolve" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable DaVinci Resolve (video editor). Requires a real GPU with OpenCL (NVIDIA ships its own ICD with the driver).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.davinci-resolve];

    hardware.graphics.extraPackages =
      if gpu == "intel"
      then [pkgs.intel-compute-runtime]
      else if gpu == "amd"
      then [pkgs.rocmPackages.clr.icd]
      else [];
  };
}
