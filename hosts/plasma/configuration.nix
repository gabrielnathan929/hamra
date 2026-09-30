_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "plasma";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";

    programs.optionals = {
      gui = {
        vesktop = true;
        vscode = false; # common ativa; aqui não queremos
      };

      services.samba = true;
    };
  };
}
