{inputs, ...}: {
  imports = [
    ./plugins.nix
    ./settings.nix
    ./templates.nix
    ./themes.nix
    inputs.noctalia.homeModules.default
  ];
}
