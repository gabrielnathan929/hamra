{pkgs, ...}: {
  home.packages = with pkgs; [
    evtest
    mpvpaper
    hyprpicker
    translate-shell
    gpu-screen-recorder
  ];
}
