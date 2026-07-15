{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.neovim;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.neovim = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Neovim editor.";
  };

  config.home.packages = mkIf cfg [pkgs.neovim];
}
