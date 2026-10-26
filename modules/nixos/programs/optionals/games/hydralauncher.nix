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

  umuSteamrt4 = pkgs.stdenv.mkDerivation {
    pname = "umu-steamrt4";
    version = "4.0.20261021.265997";
    src = pkgs.fetchurl {
      url = "https://repo.steampowered.com/steamrt4/images/4.0.20261021.265997/SteamLinuxRuntime_4.tar.xz";
      hash = "sha256-qp3RqrIXPmW2MfquNLheLBf+Mj2UEBMVTd0uHc6KCRA=";
    };
    sourceRoot = "SteamLinuxRuntime_4";
    dontFixup = true;
    installPhase = ''
      mkdir -p $out
      cp -a . $out/
      ln -s _v2-entry-point $out/umu
      cat > $out/umu-shim <<'SHIM'
      #!/bin/sh
      if [ "''${XDG_CURRENT_DESKTOP}" = "gamescope" ] || [ "''${XDG_SESSION_DESKTOP}" = "gamescope" ]; then
        if [ "''${STEAM_MULTIPLE_XWAYLANDS}" = "1" ]; then
          if [ -z "''${DISPLAY}" ]; then
            export DISPLAY=":1"
          fi
        fi
      fi
      exec "$@"
      SHIM
      chmod 755 $out/umu-shim
    '';
  };

  wrapper = pkgs.writeShellApplication {
    name = "hydra";
    runtimeInputs = compatTools;
    text = ''
      export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
      export UMU_RUNTIME_UPDATE=0

      for runtime in steamrt2 steamrt3 steamrt4; do
        runtimePath="$XDG_DATA_HOME/umu/$runtime"

        if [[ -L "$runtimePath" ]]; then
          rm -f "$runtimePath"
        elif [[ -d "$runtimePath" && ! -e "$runtimePath/umu" && ! -L "$runtimePath/umu" && -x "$runtimePath/_v2-entry-point" ]]; then
          ln -s _v2-entry-point "$runtimePath/umu"
        fi
      done

      umuRuntime="$XDG_DATA_HOME/umu/steamrt4"
      umuRuntimeStamp="$XDG_DATA_HOME/umu/.hamra-steamrt4"

      if [[ "$(cat "$umuRuntimeStamp" 2>/dev/null)" != "${umuSteamrt4.version}" ]]; then
        rm -rf "$umuRuntime"
        mkdir -p "$umuRuntime"
        cp -a ${umuSteamrt4}/. "$umuRuntime/"
        chmod -R u+w "$umuRuntime"
        printf '%s\n' "${umuSteamrt4.version}" > "$umuRuntimeStamp"
      fi

      exec ${pkgs.hydralauncher}/bin/hydralauncher --no-sandbox "$@"
    '';
  };

  gamemodeLdso = pkgs.runCommand "hydra-gamemode-ldso" {} ''
    mkdir -p $out/etc
    echo ${pkgs.gamemode.lib}/lib > $out/etc/ld.so.conf
    ${pkgs.glibc.bin}/bin/ldconfig -f $out/etc/ld.so.conf -C $out/etc/ld.so.cache
  '';

  hydraLauncher = pkgs.symlinkJoin {
    name = "hydralauncher";
    paths = [pkgs.hydralauncher];
    postBuild = ''
      launcher=$(readlink $out/bin/hydralauncher)
      rm $out/bin/hydralauncher

      sed -e 's|^\(  .*-container-init "\$@"\)$|--symlink '"${gamemodeLdso}"'/etc/ld.so.conf /etc/ld.so.conf\n--symlink '"${gamemodeLdso}"'/etc/ld.so.cache /etc/ld.so.cache\n\1|' \
        "$launcher" > $out/bin/hydralauncher
      chmod +x $out/bin/hydralauncher

      grep -q -- "--symlink ${gamemodeLdso}/etc/ld.so.cache /etc/ld.so.cache" $out/bin/hydralauncher

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
