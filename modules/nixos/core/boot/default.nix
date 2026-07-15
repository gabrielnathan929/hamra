{lib, ...}: {
  options.hamra.boot.loader = lib.mkOption {
    type = lib.types.str;
    default = "systemd-boot";
    description = "Bootloader do sistema (systemd-boot ou grub).";
  };

  imports = [
    ./grub.nix
    ./systemd-boot.nix
  ];
}
