{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.shell.aliases;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.shell.aliases = mkOption {
    type = types.bool;
    default = false;
    description = "Enable shell aliases.";
  };

  config.programs.zsh.shellAliases = mkIf cfg {
    ls = "eza --icons";
    ll = "eza -la  --icons --group-directories-first";
    la = "eza -a   --icons --group-directories-first";
    lt = "eza -T   --icons --group-directories-first";
    lta = "eza -Ta  --icons --group-directories-first";

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

    nix-deploy = "nix run .#deploy-desktop";
    nix-deploy-vm = "nix run .#deploy-vm";
    nix-build = "nix run .#build-desktop";
    nix-build-vm = "nix run .#build-vm";
  };
}
