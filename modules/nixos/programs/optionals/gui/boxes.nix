{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.boxes;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.boxes = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNOME Boxes with 3D acceleration (virgl/virtio-gpu).";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [gnome-boxes];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = lib.mkDefault pkgs.qemu;
        runAsRoot = lib.mkDefault false;
        swtpm.enable = lib.mkDefault true;
      };
    };

    users.users.${config.hamra.users.userName}.extraGroups = [
      "libvirtd"
      "render"
      "kvm"
    ];
  };
}
