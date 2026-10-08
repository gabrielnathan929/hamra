{...}: {
  imports = [
    ./audio.nix
    ./display-manager
    ./keyboard.nix
    ./power.nix
    ./printing.nix
    ./security
    ./silent-sddm.nix
    ./upower.nix
  ];
}
