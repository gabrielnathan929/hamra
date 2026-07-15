# How to change icons & cursors:
#
#   icon theme  → gtk.nix (home) — gtk.iconTheme.name
#   icon pkg    → home.programs.apps.gtk → gtk.iconTheme.package
#   cursor pkg  → packages.nix (system) — bibata-cursors
#   cursor sel  → session.nix (system) — XCURSOR_THEME
#   cursor size → session.nix (system) — XCURSOR_SIZE
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    bibata-cursors
  ];
}
