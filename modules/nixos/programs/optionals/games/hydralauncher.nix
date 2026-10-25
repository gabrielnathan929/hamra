{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.hydralauncher;
  games = config.hamra.programs.optionals.games;
  inherit (lib) mkOption mkIf types optional;

  compatTools =
    optional games.gamemode pkgs.gamemode
    ++ optional games.mangohud pkgs.mangohud
    ++ optional games.umu pkgs.umu-launcher
    ++ optional games.wine pkgs.wine
    ++ [pkgs.python3 pkgs.winetricks pkgs.coreutils];

  wrapper = pkgs.writeShellApplication {
    name = "hydra";
    runtimeInputs = compatTools;
    text = ''
      export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"

      for runtime in steamrt2 steamrt3 steamrt4; do
        runtimePath="$XDG_DATA_HOME/umu/$runtime"

        if [[ -L "$runtimePath" ]]; then
          rm -f "$runtimePath"
        elif [[ -d "$runtimePath" && ! -e "$runtimePath/umu" && ! -L "$runtimePath/umu" && -x "$runtimePath/_v2-entry-point" ]]; then
          ln -s _v2-entry-point "$runtimePath/umu"
        fi
      done

      exec ${pkgs.hydralauncher}/bin/hydralauncher --no-sandbox "$@"
    '';
  };

  hydraLauncher = pkgs.symlinkJoin {
    name = "hydralauncher";
    paths = [pkgs.hydralauncher];
    postBuild = ''
      rm -f $out/share/applications/hydralauncher.desktop
    '';
    passthru.updateScript = pkgs.hydralauncher.updateScript;
  };

  desktop = pkgs.makeDesktopItem {
    name = "hydra";
    desktopName = "Hydra";
    exec = "hydra %U";
    icon = "hydralauncher";
    comment = "Game launcher with an embedded bittorrent client";
    categories = ["Game"];
    mimeTypes = ["x-scheme-handler/hydralauncher"];
    startupWMClass = "Hydra";
  };
in {
  options.hamra.programs.optionals.games.hydralauncher = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Hydra Launcher (game launcher with embedded bittorrent client, launched through a wrapper that puts umu-launcher, GameMode, MangoHud and Winetricks on its PATH and keeps the umu runtime complete).";
  };

  config = mkIf cfg {
    environment.systemPackages = [
      hydraLauncher
      wrapper
      desktop
    ];
  };
}
