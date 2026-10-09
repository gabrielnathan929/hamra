{lib, ...}: {
  imports = [
    ./assertions.nix
    ./boot
    ./envs
    ./firewall.nix
    ./fonts.nix
    ./hardware
    ./home-manager.nix
    ./locale.nix
    ./maintenance.nix
    ./networking.nix
    ./packages.nix
    ./services
    ./theme
    ./timezone.nix
    ./users.nix
    ./webapps.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";
}
