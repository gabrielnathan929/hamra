{pkgs, ...}: let
  next = import ../scripts/workspace-next.nix {inherit pkgs;};
  prev = import ../scripts/workspace-prev.nix {inherit pkgs;};
in ''
  Mod+Tab                 { spawn-sh "${next}"; }
  Mod+Shift+Tab           { spawn-sh "${prev}"; }

  Mod+1                   { focus-workspace 1; }
  Mod+2                   { focus-workspace 2; }
  Mod+3                   { focus-workspace 3; }
  Mod+4                   { focus-workspace 4; }
  Mod+5                   { focus-workspace 5; }
  Mod+6                   { focus-workspace 6; }
  Mod+7                   { focus-workspace 7; }
  Mod+8                   { focus-workspace 8; }
  Mod+9                   { focus-workspace 9; }
  Mod+0                   { focus-workspace 10; }

  Mod+Shift+1             { move-column-to-workspace 1; }
  Mod+Shift+2             { move-column-to-workspace 2; }
  Mod+Shift+3             { move-column-to-workspace 3; }
  Mod+Shift+4             { move-column-to-workspace 4; }
  Mod+Shift+5             { move-column-to-workspace 5; }
  Mod+Shift+6             { move-column-to-workspace 6; }
  Mod+Shift+7             { move-column-to-workspace 7; }
  Mod+Shift+8             { move-column-to-workspace 8; }
  Mod+Shift+9             { move-column-to-workspace 9; }
  Mod+Shift+0             { move-column-to-workspace 10; }

  Mod+Shift+Alt+1         { move-column-to-workspace 1; }
  Mod+Shift+Alt+2         { move-column-to-workspace 2; }
  Mod+Shift+Alt+3         { move-column-to-workspace 3; }
  Mod+Shift+Alt+4         { move-column-to-workspace 4; }
  Mod+Shift+Alt+5         { move-column-to-workspace 5; }
  Mod+Shift+Alt+6         { move-column-to-workspace 6; }
  Mod+Shift+Alt+7         { move-column-to-workspace 7; }
  Mod+Shift+Alt+8         { move-column-to-workspace 8; }
  Mod+Shift+Alt+9         { move-column-to-workspace 9; }
  Mod+Shift+Alt+0         { move-column-to-workspace 10; }
''
