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
    description = "Enable gpu-screen-recorder (Noctalia screen_recorder plugin) with GPU groups and cap_sys_admin wrapper for gsr-kms-server.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.gpu-screen-recorder];

    security.wrappers.gsr-kms-server = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+ep";
      source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    };

    users.users.${config.hamra.users.userName}.extraGroups = [
      "video"
      "render"
    ];
  };
}
