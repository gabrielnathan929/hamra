{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    adw-gtk3
    bibata-cursors
    papirus-icon-theme
  ];
}
