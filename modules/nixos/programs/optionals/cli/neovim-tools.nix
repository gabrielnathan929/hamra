{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli."neovim-tools";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli."neovim-tools" = mkOption {
    type = types.bool;
    default = false;
    description = "Install Neovim companion tooling (LSP servers, formatters, ripgrep/fd/lazygit) used by the hamra.home.programs.editors.neovim configuration.";
  };

  config.environment.systemPackages = mkIf cfg (
    with pkgs; [
      lua-language-server
      nil
      ripgrep
      fd
      lazygit
      alejandra
      stylua
    ]
  );
}
