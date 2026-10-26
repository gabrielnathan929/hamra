{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.saves;
  inherit (lib) mkOption mkIf types;

  hamra-saves = pkgs.writeShellApplication {
    name = "hamra-saves";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gawk
      pkgs.gnused
      pkgs.jq
      pkgs.ludusavi
      pkgs.procps
      pkgs.rsync
      pkgs.xdg-utils
      (pkgs.python3.withPackages (ps: [ps.plyvel]))
    ];
    text = ''
      savesDir="''${HAMRA_SAVES_DIR:-$HOME/Saves}"
      hydraDir="''${XDG_CONFIG_HOME:-$HOME/.config}/hydralauncher"
      prefixesDir="$hydraDir/wine-prefixes"
      stateDir="''${XDG_DATA_HOME:-$HOME/.local/share}/hamra/saves"
      luduConfig="$stateDir/ludusavi"
      titles=""
      tmpDir=""
      quiet=0

      cleanup() {
        if [ -n "$tmpDir" ]; then
          rm -rf "$tmpDir"
        fi
      }
      trap cleanup EXIT

      usage() {
        cat <<'EOF'
      usage: hamra-saves <command>

        list                    Hydra games and what is already in ~/Saves
        adopt [--yes] [game...] move a game's saves to ~/Saves/<game> and leave
                                a symlink behind (no game: every game)
        adopt --dry-run [...]   only print what would be done
        adopt --auto            quiet run used by the timer; skipped while a
                                game is running
        detach [game...]        move the saves back and keep the ~/Saves copy
        open                    open the ~/Saves folder
      EOF
      }

      ensureState() {
        mkdir -p "$savesDir" "$luduConfig" "$stateDir/links"
      }

      readTitles() {
        python3 - "$1" <<'PY'
      import json
      import sys

      import plyvel

      db = plyvel.DB(sys.argv[1], create_if_missing=False)
      titles = {}
      for key, value in db:
          name = key.decode("utf-8", "replace")
          if not name.startswith("!gameShopAssets!"):
              continue
          try:
              data = json.loads(value)
          except ValueError:
              continue
          object_id = str(data.get("objectId") or "")
          title = data.get("title")
          if object_id and title:
              titles[object_id] = title
      db.close()
      for object_id in sorted(titles):
          print(f"{object_id}\t{titles[object_id]}")
      PY
      }

      loadTitles() {
        if [ -n "$titles" ]; then
          return 0
        fi
        if [ ! -d "$hydraDir/hydra-db" ]; then
          return 0
        fi

        tmpDir="$(mktemp -d)"
        cp -a "$hydraDir/hydra-db" "$tmpDir/db"

        if ! titles="$(readTitles "$tmpDir/db")"; then
          titles=""
        fi
      }

      cleanTitle() {
        printf '%s' "$1" | sed 's/™//g; s/®//g; s/©//g'
      }

      titleOf() {
        local id="$1"
        local title
        title="$(printf '%s\n' "$titles" | awk -F '\t' -v id="$id" '$1 == id { print $2; exit }')"
        cleanTitle "''${title:-$id}"
      }

      idOf() {
        local wanted="$1"
        local found
        if [ -d "$prefixesDir/$wanted" ]; then
          printf '%s' "$wanted"
          return 0
        fi
        found="$(printf '%s\n' "$titles" | awk -F '\t' -v w="$wanted" 'tolower($2) == tolower(w) { print $1; exit }')"
        if [ -n "$found" ]; then
          printf '%s' "$found"
          return 0
        fi
        return 1
      }

      ludusaviJson() {
        local title="$1"
        local prefix="$2"
        local output
        output="$({ ludusavi --config "$luduConfig" backup "$title" --wine-prefix "$prefix" --preview --api 2>/dev/null || true; } || true)"
        if [ -z "$output" ]; then
          output='{}'
        fi
        printf '%s' "$output"
      }

      saveDirs() {
        printf '%s' "$1" | jq -r '.games // {} | to_entries[] | .value.files // {} | keys[]' 2>/dev/null \
          | while IFS= read -r path; do
            dirname -- "$path"
          done | sort -u || true
      }

      hasRegistry() {
        printf '%s' "$1" | jq -e '([(.games // {}) | to_entries[] | (.value.registry // {}) | length] | add // 0) > 0' >/dev/null 2>&1
      }

      gamesRunning() {
        pgrep -u "$(id -u)" -f 'umu-run|_v2-entry-point|pressure-vessel|wineserver|wine-preloader|proton waitforexitandrun' >/dev/null 2>&1
      }

      fallbackDirs() {
        local title="$1"
        local prefix="$2"
        local userRoot="$prefix/drive_c/users/steamuser"
        local candidate
        for candidate in \
          "$userRoot/Saved Games/$title" \
          "$userRoot/AppData/Roaming/$title" \
          "$userRoot/AppData/Local/$title" \
          "$userRoot/AppData/LocalLow/$title"; do
          if [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
          fi
        done
      }

      isShared() {
        local dir="$1"
        local prefix="$2"
        local userRoot="$prefix/drive_c/users/steamuser"
        local publicRoot="$prefix/drive_c/users/Public"
        case "$dir" in
          "$HOME" | "$HOME/Documents" | "$HOME/Documentos" | \
            "$HOME/Desktop" | "$HOME/Área de trabalho" | \
            "$HOME/Downloads" | "$HOME/Pictures" | "$HOME/Imagens" | \
            "$HOME/Music" | "$HOME/Músicas" | "$HOME/Videos" | "$HOME/Vídeos" | \
            "$userRoot" | "$userRoot/Documents" | "$userRoot/Desktop" | \
            "$userRoot/Downloads" | "$userRoot/Music" | "$userRoot/Pictures" | \
            "$userRoot/Videos" | "$userRoot/Saved Games" | "$userRoot/AppData" | \
            "$userRoot/AppData/Roaming" | "$userRoot/AppData/Local" | \
            "$userRoot/AppData/LocalLow" | "$publicRoot" | "$publicRoot/Documents")
            return 0
            ;;
        esac
        return 1
      }

      linkDir() {
        local source="$1"
        local target="$2"

        if [ "$(readlink -f -- "$source")" = "$(readlink -f -- "$target")" ]; then
          if [ "$quiet" -eq 0 ]; then
            echo "  already adopted: $target"
          fi
          return 0
        fi
        if [ ! -e "$source" ]; then
          echo "  missing: $source" >&2
          return 0
        fi

        mkdir -p "$(dirname -- "$target")"
        if [ -e "$target" ]; then
          if ! rsync -a "$source/" "$target/"; then
            echo "  failed to merge into $target" >&2
            return 1
          fi
          if ! mv -- "$source" "$source.hamra-saves-old"; then
            echo "  failed to move $source aside" >&2
            return 1
          fi
        elif ! mv -- "$source" "$target"; then
          echo "  failed to move $source to $target" >&2
          return 1
        fi
        ln -s "$target" "$source"
        echo "  $source -> $target"
      }

      adoptGame() {
        local id="$1"
        local assumeYes="$2"
        local dryRun="$3"
        local prefix="$prefixesDir/$id"
        local title json answer dir name index
        local -a dirs=()

        title="$(titleOf "$id")"
        if [ ! -d "$prefix" ]; then
          echo "$title: no prefix yet, run the game once" >&2
          return 1
        fi

        json="$(ludusaviJson "$title" "$prefix")"
        if [ "$(printf '%s' "$json" | jq '.games // {} | length' 2>/dev/null || echo 0)" -eq 0 ]; then
          while IFS= read -r dir; do
            dirs+=("$dir")
          done < <(fallbackDirs "$title" "$prefix")
        else
          while IFS= read -r dir; do
            if [ -z "$dir" ]; then
              continue
            fi
            case "$dir" in
              "$savesDir" | "$savesDir"/*) continue ;;
            esac
            if [ -L "$dir" ]; then
              case "$(readlink -f -- "$dir")" in
                "$savesDir" | "$savesDir"/*) continue ;;
              esac
            fi
            if isShared "$dir" "$prefix"; then
              echo "$title: '$dir' is shared, skipping" >&2
              continue
            fi
            dirs+=("$dir")
          done < <(saveDirs "$json")
        fi

        local -a pending=() pendingTargets=()
        index=0
        for dir in "''${dirs[@]}"; do
          index=$((index + 1))
          if [ "''${#dirs[@]}" -eq 1 ]; then
            name="$savesDir/$title"
          else
            name="$(basename -- "$dir")"
            if [ "$index" -gt 1 ]; then
              name="$name-$index"
            fi
            name="$savesDir/$title/$name"
          fi
          if [ "$(readlink -f -- "$dir")" = "$(readlink -f -- "$name")" ]; then
            continue
          fi
          pending+=("$dir")
          pendingTargets+=("$name")
        done

        if [ "''${#pending[@]}" -eq 0 ]; then
          if [ "$quiet" -eq 0 ]; then
            if [ -s "$stateDir/links/$id" ] || [ -d "$savesDir/$title" ]; then
              echo "$title: already adopted ($savesDir/$title)"
            else
              echo "$title: no saves found (run the game and create a save first)"
            fi
          fi
          return 0
        fi

        echo "$title:"
        printf '  %s\n' "''${pending[@]}"

        if hasRegistry "$json"; then
          echo "  warning: this game also writes to the Windows registry; ~/Saves does not cover that" >&2
        fi

        if [ "$dryRun" -eq 1 ]; then
          return 0
        fi

        if [ "$assumeYes" -ne 1 ]; then
          printf 'Move to %s and leave a symlink behind? [y/N] ' "$savesDir/$title"
          read -r answer || answer=""
          case "$answer" in
            y | Y | s | S) ;;
            *)
              echo "skipped"
              return 0
              ;;
          esac
        fi

        index=0
        for dir in "''${pending[@]}"; do
          linkDir "$dir" "''${pendingTargets[$index]}"
          index=$((index + 1))
        done

        {
          if [ -f "$stateDir/links/$id" ]; then
            cat "$stateDir/links/$id"
          fi
          printf '%s\n' "''${dirs[@]}"
        } | sort -u > "$stateDir/links/$id.tmp"
        mv -- "$stateDir/links/$id.tmp" "$stateDir/links/$id"
      }

      detachGame() {
        local id="$1"
        local title record link target tmp
        title="$(titleOf "$id")"
        record="$stateDir/links/$id"

        if [ ! -s "$record" ]; then
          echo "$title: nothing adopted (run hamra-saves adopt first)" >&2
          return 1
        fi

        while IFS= read -r link; do
          target="$(readlink -f -- "$link")"
          if [ -z "$target" ] || [ ! -e "$target" ]; then
            echo "$title: broken link $link" >&2
            continue
          fi
          tmp="$link.hamra-detach"
          rm -rf "$tmp"
          if ! cp -a "$target" "$tmp"; then
            echo "$title: failed to copy $target" >&2
            continue
          fi
          rm -- "$link"
          mv -- "$tmp" "$link"
          echo "$title: restored $link (copy kept in $target)"
        done < "$record"

        rm -f "$record"
      }

      listGames() {
        local id title record count linked short
        short="~"
        printf '%-9s %-32s %s\n' "ID" "GAME" "ADOPTED SAVES"
        if [ ! -d "$prefixesDir" ]; then
          return 0
        fi
        while IFS= read -r id; do
          title="$(titleOf "$id")"
          record="$stateDir/links/$id"
          if [ -s "$record" ]; then
            count="$(awk 'END { print NR }' "$record")"
            if [ "$count" -eq 1 ]; then
              linked="$short/Saves/$title (1 link)"
            else
              linked="$short/Saves/$title ($count links)"
            fi
          elif [ -d "$savesDir/$title" ]; then
            linked="$short/Saves/$title"
          else
            linked="-"
          fi
          printf '%-9s %-32s %s\n' "$id" "$title" "$linked"
        done < <(find "$prefixesDir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)
      }

      commandName="''${1:-}"
      if [ "$#" -gt 0 ]; then
        shift
      fi

      ensureState
      loadTitles

      case "$commandName" in
        list)
          listGames
          ;;
        adopt)
          assumeYes=0
          dryRun=0
          auto=0
          targets=()
          for argument in "$@"; do
            case "$argument" in
              --yes | -y) assumeYes=1 ;;
              --dry-run | -n) dryRun=1 ;;
              --auto)
                auto=1
                assumeYes=1
                quiet=1
                ;;
              *) targets+=("$argument") ;;
            esac
          done
          if [ "$auto" -eq 1 ] && gamesRunning; then
            echo "a game is running, skipping this round"
            exit 0
          fi
          if [ "''${#targets[@]}" -eq 0 ] && [ -d "$prefixesDir" ]; then
            while IFS= read -r target; do
              targets+=("$target")
            done < <(find "$prefixesDir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)
          fi
          for target in "''${targets[@]}"; do
            if ! id="$(idOf "$target")"; then
              echo "game not found: $target" >&2
              continue
            fi
            adoptGame "$id" "$assumeYes" "$dryRun" || true
          done
          ;;
        detach)
          for target in "$@"; do
            if ! id="$(idOf "$target")"; then
              echo "game not found: $target" >&2
              continue
            fi
            detachGame "$id" || true
          done
          ;;
        open)
          xdg-open "$savesDir"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    '';
  };
in {
  options.hamra.programs.optionals.games.saves = mkOption {
    type = types.bool;
    default = false;
    description = "Enable the ~/Saves folder and the hamra-saves helper (keeps each game's saves in one place, like ~/Games).";
  };

  config = mkIf cfg {
    environment.systemPackages = [hamra-saves];

    systemd.user.services.hamra-saves = {
      description = "Adopt Hydra game saves into ~/Saves";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${hamra-saves}/bin/hamra-saves adopt --auto";
      };
    };

    systemd.user.timers.hamra-saves = {
      description = "Adopt Hydra game saves into ~/Saves";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnStartupSec = "1min";
        OnUnitActiveSec = "2h";
      };
    };
  };
}
