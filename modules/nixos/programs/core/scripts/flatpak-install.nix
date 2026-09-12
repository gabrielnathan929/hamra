{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts."flatpak-install";
  inherit (lib) mkOption mkIf types;

  flatpak-install = pkgs.writeShellScriptBin "flatpak-install" ''
    set -e

    FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

    for remote in $(flatpak remotes --system --columns=name,url 2>/dev/null \
      | grep "$FLATHUB_URL" | cut -f1); do
      sudo flatpak remote-delete --system "$remote" >/dev/null 2>&1 || true
    done

    for remote in $(flatpak remotes --user --columns=name,url 2>/dev/null \
      | grep "$FLATHUB_URL" | cut -f1); do
      flatpak remote-delete --user "$remote" >/dev/null 2>&1 || true
    done

    sudo flatpak remote-add --if-not-exists --system flathub "$FLATHUB_URL"

    app_ids=$(sudo flatpak remote-ls --system --app flathub --columns=application,name,description \
      | fzf --multi \
            --with-nth=2,3 \
            --delimiter='\t' \
            --preview 'flatpak remote-info --system flathub {1}' \
            --preview-label='Tab: select, Enter: install, Esc: cancel' \
            --preview-label-pos='bottom' \
            --preview-window 'down:65%:wrap' \
            --bind 'alt-p:toggle-preview' \
            --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up' \
            --bind 'alt-k:preview-up,alt-j:preview-down' \
            --color 'pointer:green,marker:green' \
      | cut -f1)

    if [[ -n $app_ids ]]; then
      echo "$app_ids" | tr '\n' ' ' | xargs sudo flatpak install --system --noninteractive flathub
      echo "Done."
    fi
  '';
in {
  options.hamra.programs.core.scripts."flatpak-install" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable flatpak-install (FZF browser for Flathub).";
  };

  config.environment.systemPackages = mkIf cfg [flatpak-install];
}
