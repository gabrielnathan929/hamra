{
  config,
  lib,
  pkgs,
  ...
}: let
  env = config.hamra.env;

  binName = name: pkg: pkg.meta.mainProgram or pkg.pname or name;
in {
  options.hamra.env = {
    editor = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
      description = "Editor padrão (\$EDITOR).";
    };
    browser = lib.mkOption {
      type = lib.types.package;
      default = pkgs.helium;
      description = "Navegador padrão (\$BROWSER).";
    };
    terminal = lib.mkOption {
      type = lib.types.package;
      default = pkgs.foot;
      description = "Terminal padrão (\$TERMINAL).";
    };
    filemanager = lib.mkOption {
      type = lib.types.package;
      default = pkgs.thunar;
      description = "Gerenciador de arquivos padrão (\$FILE_MANAGER).";
    };
  };

  config = {
    environment.sessionVariables = builtins.mapAttrs binName env;
    environment.systemPackages = builtins.attrValues env;

    programs.git = {
      enable = true;
      config.core.editor = lib.getExe env.editor;
    };
  };
}
