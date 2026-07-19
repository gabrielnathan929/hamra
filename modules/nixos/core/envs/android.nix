{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.mobile.android;
  inherit (lib) mkEnableOption mkIf;
  user = config.hamra.users.userName;
  sdk = "/home/${user}/Android/Sdk";
in {
  options.hamra.mobile.android = mkEnableOption "Android development environment variables";

  config = mkIf cfg {
    environment.sessionVariables = {
      ANDROID_HOME = sdk;
      ANDROID_SDK_ROOT = sdk;
      ANDROID_SDK_HOME = "/home/${user}/.var/app/com.google.AndroidStudio/config/.android";
      ANDROID_AVD_HOME = "/home/${user}/.var/app/com.google.AndroidStudio/config/.android/avd";

      PATH = [
        "/home/${user}/.npm-global/bin"
        "${sdk}/tools"
        "${sdk}/tools/bin"
        "${sdk}/emulator"
        "${sdk}/platform-tools"
      ];
    };

    environment.systemPackages = let
      android-fhs = pkgs.buildFHSEnv {
        name = "android-emulator";

        targetPkgs = pkgs: with pkgs; [
          libbsd
          libpng
          libpulseaudio
          libX11
          libxcb
          libXi
          libxkbfile
          libXtst
          libXext
          libXrandr
          libXrender
          libXfixes
          libXcursor
          libXcomposite
          libXdamage
          libXinerama
          libxshmfence
          libICE
          libSM
          fontconfig
          freetype
          zlib
          libxkbcommon
          libdrm
          expat
          nss
          nspr
          libjpeg_turbo
          libtiff
          pixman
          dbus
          pcre2
          libgbm
          utillinux
          libffi
          libglvnd
          mesa
        ];

        runScript = "${pkgs.writeShellScript "emu" ''
          export LD_LIBRARY_PATH="${sdk}/emulator/lib64:${sdk}/emulator/lib64/qt/lib:$LD_LIBRARY_PATH"
          exec ${sdk}/emulator/emulator "$@"
        ''}";
      };
    in [
      android-fhs
    ];

    environment.shellAliases = {
      pixel7 = ''android-emulator @Pixel_7 -no-boot-anim -no-snapshot-load -gpu swiftshader_indirect -accel on -memory 4096'';
      pixel7-gpu = ''android-emulator @Pixel_7 -no-boot-anim -no-snapshot-load -gpu host -accel on -memory 4096'';
    };
  };
}
