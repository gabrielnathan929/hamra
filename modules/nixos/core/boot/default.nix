{lib, ...}: {
  options.hamra.boot.loader = lib.mkOption {
    type = lib.types.str;
    default = "systemd-boot";
    description = "Bootloader (systemd-boot or grub).";
  };

  imports = [
    ./grub.nix
    ./systemd-boot.nix
  ];
}
