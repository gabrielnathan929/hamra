{
  config,
  lib,
  ...
}: let
  displayManager = config.hamra.displayManager;
in {
  programs.silentSDDM =
    lib.mkIf
    (
      displayManager.default
      == "sddm"
      && (displayManager.sddm.theme == "silent" || displayManager.sddm.preset != null)
    )
    {
      enable = true;
      theme = displayManager.sddm.preset or "rei";
      profileIcons.${config.hamra.users.userName} = displayManager.sddm.profileIcon;
    };
}
