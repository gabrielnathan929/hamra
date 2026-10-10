{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.shell.aliases;
  inherit (lib) mkOption mkIf mkAfter types;
in {
  options.hamra.home.programs.shell.aliases = mkOption {
    type = types.bool;
    default = true;
    description = "Enable shell aliases.";
  };

  config.programs.zsh = mkIf cfg {
    shellAliases = {
      ll = "eza -la  --icons --group-directories-first";
      la = "eza -a   --icons --group-directories-first";

      nix-run = "nix run nixpkgs#";
      nix-boot = "sudo nixos-rebuild boot";
      nix-test = "sudo nixos-rebuild test";
      nix-builds = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations | sort -k1 -n -r";
      nix-clean = "nix-env --delete-generations old && sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old && sudo nix-store --gc";
      nix-dup = ''echo "=== System ==="; for gen in /nix/var/nix/profiles/system-*-link(N); do nix-store -qR "$gen" 2>/dev/null; done | sort -u | grep -v '\.drv$' | sed 's|.*/||' | sed -E 's/^[a-z0-9]{32}-//' | sed -E 's/-[0-9].*$//' | sort | uniq -c | sort -rn | awk '$1 > 1 {printf "%-30s %dx\n", $2, $1}' '';
      nix-gc = "sudo nix-store --gc";
      nix-tidy = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5 && nix-env --delete-generations old && sudo nix-store --gc";
      nix-scrub = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old && nix-env --delete-generations old && sudo nix-store --gc && sudo nix-store --optimise";
      nix-optim = "sudo nix-store --optimise";
      nix-shell = "nix-shell -p";
      nix-switch = "sudo nixos-rebuild switch";
      nix-search = "nix-search";

      nix-deploy = "nix run .#deploy-$(hostname)";
      nix-deploy-vm = "nix run .#deploy-vm";
      nix-build = "nix run .#build-$(hostname)";
      nix-build-vm = "nix run .#build-vm";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      g = "git";
      gcm = "git commit -m";
      gcam = "git commit -a -m";
      gcad = "git commit -a --amend";
    };

    initContent = mkAfter ''
      if command -v eza &> /dev/null; then
        alias ls='eza -lh --group-directories-first --icons=auto'
        alias lsa='ls -a'
        alias lt='eza --tree --level=2 --long --icons --git'
        alias lta='lt -a'
      fi

      if [[ $TERM == "xterm-kitty" ]]; then
        alias ff="fzf --preview 'case $(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=''${FZF_PREVIEW_COLUMNS}x''${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
      else
        alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
      fi
      alias eff='$EDITOR "$(ff)"'
      sff() { if [ $# -eq 0 ]; then echo "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; fi; local file; file=$(find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff) && [ -n "$file" ] && scp "$file" "$1"; }

      if command -v zoxide &> /dev/null; then
        alias cd="zd"
        zd() {
          if (( $# == 0 )); then
            builtin cd ~ || return
          elif [[ -d $1 ]]; then
            builtin cd "$1" || return
          else
            if ! z "$@"; then
              echo "Error: Directory not found"
              return 1
            fi

            printf "\U000F17A9 "
            pwd
          fi
        }
      fi

      open() (
        xdg-open "$@" >/dev/null 2>&1 &
      )
    '';
  };
}
