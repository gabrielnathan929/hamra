{
  lib,
  desktop,
  ...
}: {
  imports =
    lib.optionals (builtins.elem desktop ["hyprland" "niri" "sway"]) [
      ./noctalia
    ]
    ++ lib.optionals (desktop == "hyprland") [
      ./hyprland
    ]
    ++ lib.optionals (desktop == "niri") [
      ./niri
    ]
    ++ lib.optionals (desktop == "sway") [
      ./sway
    ];
}
