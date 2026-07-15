# ─────────────────────────────────────────────────────────────
#  Hamra Home Desktops Entrypoint
#  Importa condicionalmente as configurações do Home Manager
#  específicas de cada ambiente gráfico (Hyprland, Niri, Sway) + Noctalia shell.
# ─────────────────────────────────────────────────────────────
{
  lib,
  desktop,
  ...
}: {
  imports =
    [
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
