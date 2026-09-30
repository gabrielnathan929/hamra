_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "desktop";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";

    programs = {
      core = {
        tui = {
          codex = true;
          antigravity = true;
        };

        noctalia = {
          "gpu-screen-recorder" = true;
          evtest = true;
          mpvpaper = true;
          hyprpicker = true;
          "translate-shell" = true;
        };
      };

      optionals = {
        gui = {
          obsidian = true;
          office = true;
          drawio = true;
          localsend = true;
          nautilus = true;
        };

        media = {
          spotify = true;
          spicetify = true;
          kodi = true;
          obs = true;
        };

        cli = {
          rclone = true;
          go = true;
          jdk = true;
          gcc = true;
          gnumake = true;
          nodejs = true;
          python3 = true;
          ripgrep = true;
        };

        tui = {
          lazygit = true;
          lazydocker = true;
        };

        packaging = {
          flatpak = true;
          "gnome-software" = true;
        };

        services = {
          samba = true;
          appimage = true;
          docker = true;
          "docker-compose" = true;
        };
      };
    };
  };
}
