{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.development.git;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.development.git = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Git with GPG signing.";
  };

  config.programs.git = mkIf cfg {
    enable = true;
    lfs.enable = true;
    config = {
      core.editor = lib.getExe config.hamra.env.editor;
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
