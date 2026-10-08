{
  config,
  lib,
  ...
}: let
  enums = import ../../lib/enums.nix;

  validGPUs = enums.gpus;
  validFirmware = enums.firmware;
  validAudio = enums.audio;
  validBootloaders = enums.bootloaders;
  validDesktops = enums.desktops;
  validDisplayManagers = enums.displayManagers;

  availableThemes = import ./theme/themes/themes-list.nix;

  cfg = config.hamra;
in {
  assertions = [
    {
      assertion = builtins.elem cfg.boot.loader validBootloaders;
      message =
        "hamra.boot.loader = \"${cfg.boot.loader}\" invalid. "
        + "Valid values: ${builtins.toString validBootloaders}";
    }

    {
      assertion = builtins.elem cfg.hardware.gpu validGPUs;
      message =
        "hamra.hardware.gpu = \"${cfg.hardware.gpu}\" invalid. "
        + "Valid values: ${builtins.toString validGPUs}";
    }

    {
      assertion = builtins.elem cfg.hardware.firmware validFirmware;
      message =
        "hamra.hardware.firmware = \"${cfg.hardware.firmware}\" invalid. "
        + "Valid values: ${builtins.toString validFirmware}";
    }

    {
      assertion = builtins.elem cfg.audio.default validAudio;
      message =
        "hamra.audio.default = \"${cfg.audio.default}\" invalid. "
        + "Valid values: ${builtins.toString validAudio}";
    }

    {
      assertion = builtins.elem cfg.desktop.default validDesktops;
      message =
        "hamra.desktop.default = \"${cfg.desktop.default}\" invalid. "
        + "Valid values: ${builtins.toString validDesktops}";
    }

    {
      assertion = builtins.elem cfg.displayManager.default validDisplayManagers;
      message =
        "hamra.displayManager.default = \"${cfg.displayManager.default}\" invalid. "
        + "Valid values: ${builtins.toString validDisplayManagers}";
    }

    {
      assertion =
        cfg.boot.loader != "grub" || (cfg.boot.grub.device != "" && cfg.boot.grub.device != null);
      message =
        "hamra.boot.loader = \"grub\" requer " + "hamra.boot.grub.device definido (ex: \"/dev/sda\").";
    }

    {
      assertion = builtins.elem cfg.theme.name availableThemes;
      message =
        "hamra.theme.name = \"${cfg.theme.name}\" invalid. "
        + "Available themes: ${builtins.toString availableThemes}";
    }

    {
      assertion = builtins.pathExists cfg.theme.profileIcon;
      message =
        "hamra.theme.profileIcon does not exist: ${toString cfg.theme.profileIcon} "
        + "(theme \"${cfg.theme.name}\"). Check the file referenced by the theme module.";
    }

    {
      assertion = lib.hasSuffix ".UTF-8" cfg.locale;
      message =
        "hamra.locale = \"${cfg.locale}\" deve terminar com \".UTF-8\" "
        + "(ex: \"pt_BR.UTF-8\", \"en_US.UTF-8\").";
    }

    {
      assertion = cfg.timezone != "";
      message = "hamra.timezone cannot be empty " + "(e.g. \"America/Sao_Paulo\", \"Europe/Lisbon\").";
    }

    {
      assertion = cfg.networking.hostname != "";
      message = "hamra.networking.hostname cannot be empty.";
    }

    {
      assertion = cfg.users.userName != "";
      message = "hamra.users.userName cannot be empty.";
    }

    {
      assertion =
        !cfg.programs.optionals.services.wayvnc
        || builtins.elem cfg.desktop.default [
          "hyprland"
          "sway"
        ];
      message =
        "hamra.programs.optionals.services.wayvnc = true requer hamra.desktop.default = "
        + "\"hyprland\" ou \"sway\" (atual: \"${cfg.desktop.default}\"). "
        + "Niri does not support headless output for WayVNC.";
    }

    {
      assertion = cfg.flatpak.apps == [] || cfg.programs.optionals.packaging.flatpak;
      message = "hamra.flatpak.apps requer hamra.programs.optionals.packaging.flatpak = true.";
    }

    {
      assertion = !cfg.programs.optionals.packaging.gearlever || cfg.programs.optionals.services.appimage;
      message = "hamra.programs.optionals.packaging.gearlever requer hamra.programs.optionals.services.appimage = true.";
    }

    {
      assertion =
        !cfg.programs.optionals.media."davinci-resolve"
        || builtins.elem cfg.hardware.gpu [
          "intel"
          "amd"
          "nvidia"
        ];
      message =
        "hamra.programs.optionals.media.davinci-resolve requer GPU real (intel, amd ou nvidia) com OpenCL; "
        + "virtio is not supported (current: \"${cfg.hardware.gpu}\"). Disable this toggle on this host.";
    }

    {
      assertion =
        (cfg.mise.tools == {} && cfg.mise.env == {} && cfg.mise.settings == {})
        || cfg.programs.core.cli.mise;
      message = "hamra.mise.{tools,env,settings} requer hamra.programs.core.cli.mise = true.";
    }

    {
      assertion = lib.all (app: app.icon == null || app.iconHash != null) (lib.attrValues cfg.webapps);
      message = "hamra.webapps.<nome>.icon requer hamra.webapps.<nome>.iconHash (sha256-...).";
    }
  ];
}
