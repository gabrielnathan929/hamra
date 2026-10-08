# ─────────────────────────────────────────────────────────────
#  Hamra Home Desktops Entrypoint
#  Conditionally imports the Home Manager configuration
#  for each desktop environment (Hyprland, Niri, Sway) + Noctalia shell.
# ─────────────────────────────────────────────────────────────
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
