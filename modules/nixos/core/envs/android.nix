{
  config,
  lib,
  ...
}: let
  androidStudio = config.hamra.programs.optionals.gui."android-studio";
  inherit (lib) mkIf;
  user = config.hamra.users.userName;
  sdk = "/home/${user}/Android/Sdk";
in {
  config.environment = mkIf androidStudio {
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
}
