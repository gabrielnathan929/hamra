{
  config,
  lib,
  pkgs,
  ...
}: let
  users = config.hamra.users;
in {
  options.hamra.users = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "gabrielnathan";
      description = "Nome de usuário do sistema.";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Gabriel Nathan dos Santos Pires";
      description = "Nome completo do usuário.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "devgabrielnathan@gmail.com";
      description = "Email do usuário.";
    };
  };

  config = {
    users.users.${users.userName} = {
      isNormalUser = lib.mkDefault true;
      description = lib.mkDefault users.fullName;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;
  };
}
