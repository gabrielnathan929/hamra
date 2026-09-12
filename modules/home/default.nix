{inputs, ...}: {
  imports = [
    ./programs
    ./desktops
    inputs.spicetify-nix.homeManagerModules.default
  ];

  nixpkgs.config.allowUnfree = true;
}
