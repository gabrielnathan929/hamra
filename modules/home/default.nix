{inputs, ...}: {
  imports = [
    ./keybinds.nix
    ./programs
    ./desktops
    inputs.spicetify-nix.homeManagerModules.default
  ];

  nixpkgs.config.allowUnfree = true;
}
