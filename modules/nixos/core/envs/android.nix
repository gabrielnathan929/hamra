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
    environment = {
      sessionVariables = {
        ANDROID_HOME = sdk;
        ANDROID_SDK_ROOT = sdk;
        ANDROID_SDK_HOME = "/home/${user}/.var/app/com.google.AndroidStudio/config/.android";
        ANDROID_AVD_HOME = "/home/${user}/.var/app/com.google.AndroidStudio/config/.android/avd";

        PATH = [
          "${sdk}/tools"
          "${sdk}/tools/bin"
          "${sdk}/emulator"
          "${sdk}/platform-tools"
        ];
      };
    };
  };
}
