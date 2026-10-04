_: let
  themeNames = import ./themes-list.nix;
in {
  imports = map (name: ./. + "/${name}") themeNames;
}
