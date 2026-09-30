_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "vm";

    hardware = {
      gpu = "virtio";
      firmware = "uefi";
    };

    desktop.default = "sway";

    programs = {
      core.noctalia = {
        "gpu-screen-recorder" = true;
        evtest = true;
        mpvpaper = true;
        hyprpicker = true;
        "translate-shell" = true;
      };

      optionals = {
        gui = {
          vesktop = true;
          vscode = true;
        };

        games.moonlight-qt = true;
      };
    };
  };
}
