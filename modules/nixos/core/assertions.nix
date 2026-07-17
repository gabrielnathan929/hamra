{
  config,
  lib,
  ...
}: let
  validGPUs = [
    "intel"
    "nvidia"
    "amd"
    "virtio"
  ];
  validFirmware = [
    "uefi"
    "bios"
  ];
  validAudio = [
    "pipewire"
    "pulseaudio"
  ];
  validBootloaders = [
    "systemd-boot"
    "grub"
  ];
  validDesktops = [
    "hyprland"
    "niri"
    "sway"
  ];
  validDisplayManagers = ["sddm"];

  availableThemes = import ./theme/themes/themes-list.nix;

  cfg = config.hamra;
in {
  assertions = [
    {
      assertion = builtins.elem cfg.boot.loader validBootloaders;
      message =
        "hamra.boot.loader = \"${cfg.boot.loader}\" inválido. "
        + "Valores válidos: ${builtins.toString validBootloaders}";
    }

    {
      assertion = builtins.elem cfg.hardware.gpu validGPUs;
      message =
        "hamra.hardware.gpu = \"${cfg.hardware.gpu}\" inválido. "
        + "Valores válidos: ${builtins.toString validGPUs}";
    }

    {
      assertion = builtins.elem cfg.hardware.firmware validFirmware;
      message =
        "hamra.hardware.firmware = \"${cfg.hardware.firmware}\" inválido. "
        + "Valores válidos: ${builtins.toString validFirmware}";
    }

    {
      assertion = builtins.elem cfg.audio.default validAudio;
      message =
        "hamra.audio.default = \"${cfg.audio.default}\" inválido. "
        + "Valores válidos: ${builtins.toString validAudio}";
    }

    {
      assertion = builtins.elem cfg.desktop.default validDesktops;
      message =
        "hamra.desktop.default = \"${cfg.desktop.default}\" inválido. "
        + "Valores válidos: ${builtins.toString validDesktops}";
    }

    {
      assertion = builtins.elem cfg.displayManager.default validDisplayManagers;
      message =
        "hamra.displayManager.default = \"${cfg.displayManager.default}\" inválido. "
        + "Valores válidos: ${builtins.toString validDisplayManagers}";
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
        "hamra.theme.name = \"${cfg.theme.name}\" inválido. "
        + "Temas disponíveis: ${builtins.toString availableThemes}";
    }

    {
      assertion = lib.hasSuffix ".UTF-8" cfg.locale;
      message =
        "hamra.locale = \"${cfg.locale}\" deve terminar com \".UTF-8\" "
        + "(ex: \"pt_BR.UTF-8\", \"en_US.UTF-8\").";
    }

    {
      assertion = cfg.timezone != "";
      message = "hamra.timezone não pode ser vazio " + "(ex: \"America/Sao_Paulo\", \"Europe/Lisbon\").";
    }

    {
      assertion = cfg.networking.hostname != "";
      message = "hamra.networking.hostname não pode ser vazio.";
    }

    {
      assertion = cfg.users.userName != "";
      message = "hamra.users.userName não pode ser vazio.";
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
        + "Niri não suporta headless output para WayVNC.";
    }
  ];
}
