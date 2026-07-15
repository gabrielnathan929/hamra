{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.pkgs.dev;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.pkgs.dev = mkOption {
    type = types.bool;
    default = true;
    description = "Enable development packages (neovim).";
  };

  config.home.packages = mkIf cfg (with pkgs; [
    git
    neovim
  ]);
}
