_: let
  barPart = import ./bar.nix {};
  panelsPart = import ./panels.nix {};
  dockPart = import ./dock.nix {};
  widgetsPart = import ./widgets.nix {};
  pluginsPart = import ./plugins.nix {};
in ''
  ${barPart}
  ${panelsPart}
  ${dockPart}
  ${widgetsPart}
  ${pluginsPart}
''
