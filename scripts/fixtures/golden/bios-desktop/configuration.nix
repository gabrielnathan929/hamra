_: {
  imports = [
    ../../modules/nixos/core
    ../../modules/nixos/desktops
    ../../modules/nixos/programs
    ./hardware-configuration.nix
    ./config/system.nix
    ./config/hardware.nix
    ./config/desktop.nix
    ./config/programs-core.nix
    ./config/programs-optionals.nix
    ./config/home.nix
  ];
}
