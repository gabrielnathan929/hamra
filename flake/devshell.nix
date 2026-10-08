{
  pkgs,
  system,
}: {
  ${system} = {
    default = pkgs.mkShell {
      name = "hamra";

      packages = with pkgs; [
        alejandra
        statix
        deadnix
        sops
        age
        ssh-to-age
        python3
      ];

      shellHook = ''
        echo "alejandra  -> nix fmt"
        echo "statix     -> linter"
        echo "deadnix    -> dead code"
        echo "sops       -> edit secrets (e.g. sops secrets/samba.yaml)"
        echo "setup-nas  -> ./scripts/setup-nas.sh (NAS wizard)"
        echo "hamra-init -> nix run .#hamra-init (generate a new host)"
        echo "deploy     -> nix run .#deploy-<host> (validate + switch)"
        echo "build      -> nix run .#build-<host> (build without applying)"
      '';
    };
  };
}
