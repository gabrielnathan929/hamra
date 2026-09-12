{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.virtualisation."virt-manager";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.virtualisation."virt-manager" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable virt-manager with libvirtd (QEMU/KVM).";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [virt-manager];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu;
        runAsRoot = false;
        swtpm.enable = true;
      };
    };

    users.users.${config.hamra.users.userName}.extraGroups = [
      "libvirtd"
      "render"
      "kvm"
    ];
  };
}
