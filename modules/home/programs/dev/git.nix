{
  config,
  lib,
  env,
  ...
}: let
  cfg = config.hamra.home.programs.dev.git;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.git = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Git with GPG signing.";
  };

  config.programs.git = mkIf cfg {
    enable = true;
    lfs.enable = true;
    settings = {
      core.editor = lib.getExe env.editor;
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
