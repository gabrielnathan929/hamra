{inputs, ...}: {
  imports = [
    inputs.noctalia.homeModules.default
    ./settings.nix
    ./plugins.nix
    ./templates.nix
    ./themes.nix
  ];
}
