{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.noctalia."gpu-screen-recorder";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.noctalia."gpu-screen-recorder" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable GPU access groups for gpu-screen-recorder (Noctalia screen_recorder plugin).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.gpu-screen-recorder];

    users.users.${config.hamra.users.userName}.extraGroups = [
      "video"
      "render"
    ];
  };
}
