# Personal identity of this profile's owner: username, localization, theme,
# default apps and mise tools. Applies (mkDefault) to every host that
# imports the profile; a host can still override anything with plain values.
#
# Forking for personal use: copy this folder to hosts/profiles/<your-name>/,
# edit these files and point your hosts at your profile instead of this one.
# Never edit this profile in a fork.
{
  pkgs,
  lib,
  ...
}: {
  hamra = lib.mkDefault {
    users.userName = "gabrielnathan";

    locale = "pt_BR.UTF-8";
    timezone = "America/Sao_Paulo";

    theme.name = "dragon-ball";

    env = {
      editor = pkgs.neovim;
      browser = pkgs.chromium;
      terminal = pkgs.foot;
      filemanager = pkgs.thunar;
    };

    mise = {
      tools = {
        codex = "latest";
        copilot = "latest";
        gh = "latest";
        go = "latest";
        java = "latest";
        python = "latest";

        "github:herdrdev/herdr" = "latest";
        "github:google-antigravity/antigravity-cli" = "latest";
        "npm:@opencode/cli" = "latest";
      };

      settings = {
        github_attestations = false;

        python.compile = false;
      };
    };
  };
}
