{
  config,
  lib,
  pkgs,
  ...
}: let
  env = config.hamra.env;

  binName = name: pkg: pkg.meta.mainProgram or pkg.pname or name;
  sessionVars = builtins.mapAttrs binName env;
  filemanagerFromToggle = config.hamra.programs.core.gui.thunar && env.filemanager == pkgs.thunar;
in {
  options.hamra.env = {
    editor = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
      description = "Default editor (\$EDITOR).";
    };
    browser = lib.mkOption {
      type = lib.types.package;
      default = pkgs.helium;
      description = "Default browser (\$BROWSER).";
    };
    terminal = lib.mkOption {
      type = lib.types.package;
      default = pkgs.foot;
      description = "Default terminal (\$TERMINAL).";
    };
    filemanager = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nautilus;
      description = "Default file manager (\$FILE_MANAGER).";
    };
  };

  config = {
    environment.sessionVariables =
      sessionVars
      // {
        EDITOR = sessionVars.editor;
        BROWSER = sessionVars.browser;
        TERMINAL = sessionVars.terminal;
        FILE_MANAGER = sessionVars.filemanager;
      };
    environment.systemPackages = builtins.attrValues (
      if filemanagerFromToggle
      then builtins.removeAttrs env ["filemanager"]
      else env
    );

    programs.git = {
      enable = true;
      config.core.editor = lib.getExe env.editor;
    };
  };
}
