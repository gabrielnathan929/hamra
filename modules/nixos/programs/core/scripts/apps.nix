{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts.apps;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;

  mkEntry = p: let
    parsed = builtins.parseDrvName p.name;
    name = p.pname or parsed.name;
    version = p.version or parsed.version;
  in {
    inherit name;
    version =
      if version == ""
      then "-"
      else version;
  };

  manifest = builtins.toJSON {
    nix = map mkEntry (config.environment.systemPackages ++ config.home-manager.users.${userName}.home.packages);
    mise = config.hamra.mise.tools;
    flatpak = config.hamra.flatpak.apps;
    webapps =
      lib.mapAttrs (_: app: {
        name = app.desktopName;
        inherit (app) url;
      })
      config.hamra.webapps;
  };

  hamra-apps = pkgs.writeShellApplication {
    name = "hamra-apps";
    runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gnused];
    text = ''
      manifest=/etc/hamra/apps.json

      usage() {
        printf '%s\n' 'Uso: hamra-apps [termo | -v <ferramenta> | -h]'
        printf '\n'
        printf '%s\n' \
          '  hamra-apps            lista apps instalados por fonte (Nix, mise, Flatpak, web)' \
          '  hamra-apps <term>      filter the list by name (case-insensitive)' \
          '  hamra-apps -v <tool>  show available versions in the mise registry' \
          '  hamra-apps -h         mostra esta ajuda'
      }

      if [[ ! -f $manifest ]]; then
        echo "hamra-apps: manifest not found: $manifest" >&2
        exit 1
      fi

      mode=list
      query=

      if [[ $# -eq 0 ]]; then
        mode=list
      elif [[ $1 == -h || $1 == --help ]]; then
        usage
        exit 0
      elif [[ $1 == -v ]]; then
        if [[ $# -ne 2 ]]; then
          usage
          exit 1
        fi
        mode=versions
        query=$2
      elif [[ $1 == -* ]]; then
        usage
        exit 1
      else
        mode=list
        query=$1
      fi

      if [[ $mode == versions ]]; then
        if ! command -v mise >/dev/null 2>&1; then
          echo "hamra-apps: mise not found in PATH." >&2
          exit 1
        fi
        installed=$(mise ls --json 2>/dev/null | jq -r '
          if type == "array"
          then .[] | select(.installed != false) | "\(.tool // "?")\t\(.version)"
          else to_entries[] | {tool: .key, versions: [.value[] | select(.installed != false) | .version]} | select(.versions | length > 0) | "\(.tool)\t\(.versions | join(", "))"
          end
        ' 2>/dev/null | grep -F -- "$query"$'\t' | cut -f2 || true)
        versions=$(mise ls-remote "$query" 2>/dev/null | tail -n 25 || true)
        printf '%s installed: %s\n' "$query" "''${installed:-not installed}"
        if [[ -z $versions ]]; then
          echo "hamra-apps: no versions of \"$query\" in the mise registry." >&2
          exit 1
        fi
        echo
        echo "Latest available versions:"
        printf '%s\n' "$versions"
        exit 0
      fi

      nixRows=$(jq -r '.nix[] | "\(.name)\t\(.version)"' "$manifest" | sort -u)

      miseInstalled=
      if command -v mise >/dev/null 2>&1; then
        miseInstalled=$(mise ls --json 2>/dev/null | jq -r '
          if type == "array"
          then .[] | select(.installed != false) | "\(.tool // "?")\t\(.version)"
          else to_entries[] | {tool: .key, versions: [.value[] | select(.installed != false) | .version]} | select(.versions | length > 0) | "\(.tool)\t\(.versions | join(", "))"
          end
        ' 2>/dev/null || true)
      fi

      miseDeclared=$(jq -r '.mise | to_entries[] | "\(.key)\t\(.value | if type == "array" then join(" ") else . end)"' "$manifest")

      miseRows=$(printf '%s\n' "$miseInstalled" | sed '/^$/d')
      if [[ -n $miseRows ]]; then
        miseRows+=$'\n'
      fi
      installedNames=$(printf '%s\n' "$miseInstalled" | cut -f1)
      while IFS=$'\t' read -r tool requested; do
        if [[ -z $tool ]]; then
          continue
        fi
        if ! printf '%s\n' "$installedNames" | grep -qFx -- "$tool"; then
          miseRows+="$tool"$'\t'"$requested (declared, not installed)"$'\n'
        fi
      done <<< "$miseDeclared"

      flatpakRows=
      if command -v flatpak >/dev/null 2>&1; then
        flatpakRows=$(flatpak list --app --columns=application,branch,version 2>/dev/null | while read -r id branch version; do
            if [[ -z $id ]]; then
              continue
            fi
            version=''${version:-$branch}
            version=''${version:--}
            printf '%s\t%s\n' "$id" "$version"
          done | sort || true)
      fi
      if [[ -n $flatpakRows ]]; then
        flatpakRows+=$'\n'
      fi
      flatpakIds=$(printf '%s\n' "$flatpakRows" | cut -f1)
      while read -r appId; do
        if [[ -z $appId ]]; then
          continue
        fi
        if ! printf '%s\n' "$flatpakIds" | grep -qFx -- "$appId"; then
          flatpakRows+="$appId"$'\t'"(declarado, pendente)"$'\n'
        fi
      done < <(jq -r '.flatpak[]' "$manifest")

      webRows=$(jq -r '.webapps | to_entries[] | "\(.key)\t\(.value.name) — \(.value.url)"' "$manifest")

      printed=0

      applyFilter() {
        if [[ -z $query ]]; then
          printf '%s' "$1"
        else
          printf '%s' "$1" | grep -iF -- "$query" || true
        fi
      }

      section() {
        local title=$1
        local rows
        local lines
        rows=$(applyFilter "$2")
        lines=$(printf '%s\n' "$rows" | sed '/^$/d' | sort)
        if [[ -z $lines ]]; then
          return 0
        fi
        printf '\n%s (%s)\n' "$title" "$(printf '%s\n' "$lines" | grep -c .)"
        printf '%s\n' "$lines" | while IFS=$'\t' read -r name rest; do
          printf '  %-30s %s\n' "$name" "$rest"
        done
        printed=$((printed + 1))
      }

      if [[ -z $query ]]; then
        printf 'Apps instalados por fonte\n'
      else
        printf 'Apps por fonte: filtro "%s"\n' "$query"
      fi

      section "Nix" "$nixRows"
      section "mise" "$miseRows"
      section "Flatpak" "$flatpakRows"
      section "Web apps" "$webRows"

      if [[ $printed -eq 0 ]]; then
        if [[ -z $query ]]; then
          echo "Nenhum app encontrado."
        else
          echo "Nenhum app encontrado para \"$query\"."
        fi
      fi
    '';
  };
in {
  options.hamra.programs.core.scripts.apps = mkOption {
    type = types.bool;
    default = true;
    description = "Enable hamra-apps (installed apps listing by source: Nix, mise, Flatpak, web apps).";
  };

  config = mkIf cfg {
    environment.systemPackages = [hamra-apps];

    environment.etc."hamra/apps.json".text = manifest;
  };
}
