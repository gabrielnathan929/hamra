{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui."android-studio";
  inherit (lib) mkIf;
  user = config.hamra.users.userName;
  sdk = "/home/${user}/Android/Sdk";
  androidHome = "/home/${user}/.android";
  shellInit = ''
    export ANDROID_HOME="${sdk}"
    export ANDROID_SDK_ROOT="${sdk}"
    export ANDROID_USER_HOME="${androidHome}"
    export ANDROID_AVD_HOME="${androidHome}/avd"
    for dir in "${sdk}/emulator" "${sdk}/platform-tools" "${sdk}/cmdline-tools/latest/bin"; do
      case ":$PATH:" in
        *":$dir:"*) ;;
        *) [ -d "$dir" ] && PATH="$dir:$PATH" ;;
      esac
    done
    unset dir
  '';
in {
  config = mkIf cfg {
    environment.sessionVariables = {
      ANDROID_HOME = sdk;
      ANDROID_SDK_ROOT = sdk;
      ANDROID_USER_HOME = androidHome;
      ANDROID_AVD_HOME = "${androidHome}/avd";
    };

    environment.systemPackages = with pkgs; [android-tools];

    programs.bash.interactiveShellInit = shellInit;
    programs.zsh.interactiveShellInit = shellInit;
  };
}
