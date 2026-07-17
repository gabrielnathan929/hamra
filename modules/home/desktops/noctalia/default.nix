{inputs, ...}: {
  imports = [
    inputs.noctalia.homeModules.default
    ./settings.nix
    ./plugins.nix
    ./themes.nix
  ];
}
