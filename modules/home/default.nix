{inputs, ...}: {
  imports = [
    ./desktops
    ./keybinds.nix
    ./programs
    inputs.spicetify-nix.homeManagerModules.default
  ];

  nixpkgs.config.allowUnfree = true;
}
