{inputs, ...}: {
  imports = [
    inputs.noctalia.homeModules.default
    ./settings.nix
    ./plugins.nix
    ./packages.nix
    ./themes.nix
  ];
}
