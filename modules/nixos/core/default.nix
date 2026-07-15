{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./assertions.nix
    ./boot
    ./envs
    ./hardware
    ./networking.nix
    ./services
    ./locale.nix
    ./maintenance.nix
    ./timezone.nix
    ./users.nix
    ./fonts.nix
    ./theme
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["gabrielnathan"];
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

  environment.systemPackages = [pkgs.home-manager];
}
