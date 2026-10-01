{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.wireshark;
  inherit (lib) mkOption mkIf types;
  user = config.hamra.users.userName;
in {
  options.hamra.programs.optionals.gui.wireshark = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Wireshark.";
  };

  config = mkIf cfg {
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    users.users.${user}.extraGroups = ["wireshark"];
  };
}
