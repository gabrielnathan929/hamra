{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts."flatpak-remove";
  inherit (lib) mkOption mkIf types;

  flatpak-remove = pkgs.writeShellScriptBin "flatpak-remove" ''
    set -e

    app_ids=$(flatpak list --app --columns=application,name,origin,installation \
      | fzf --multi \
            --with-nth=2,3,4 \
            --delimiter='\t' \
            --preview 'flatpak info {1}' \
            --preview-label='Tab: select, Enter: remove, Esc: cancel' \
            --preview-label-pos='bottom' \
            --preview-window 'down:65%:wrap' \
            --bind 'alt-p:toggle-preview' \
            --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up' \
            --bind 'alt-k:preview-up,alt-j:preview-down' \
            --color 'pointer:red,marker:red' \
      | cut -f1)

    if [[ -n $app_ids ]]; then
      while IFS= read -r app_id; do
        [[ -z $app_id ]] && continue
        if flatpak info --system "$app_id" >/dev/null 2>&1; then
          sudo flatpak uninstall --system --noninteractive --delete-data "$app_id"
        fi
        if flatpak info --user "$app_id" >/dev/null 2>&1; then
          flatpak uninstall --user --noninteractive --delete-data "$app_id"
        fi
      done <<< "$app_ids"
      echo "Done."
    fi
  '';
in {
  options.hamra.programs.core.scripts."flatpak-remove" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable flatpak-remove (FZF browser to uninstall Flatpaks).";
  };

  config.environment.systemPackages = mkIf cfg [flatpak-remove];
}
