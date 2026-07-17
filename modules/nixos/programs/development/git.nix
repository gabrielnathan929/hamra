{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.git;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.git = mkOption {
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
