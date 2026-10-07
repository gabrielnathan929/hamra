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
        echo "deadnix    -> codigo morto"
        echo "sops       -> editar segredos (ex: sops secrets/samba.yaml)"
        echo "setup-nas  -> ./scripts/setup-nas.sh (assistente do NAS)"
        echo "nix run .#deploy-samsung -> valida + switch"
        echo "nix run .#deploy-vm -> valida + switch"
        echo "nix run .#build-samsung -> build sem aplicar"
        echo "nix run .#build-vm -> build sem aplicar"
      '';
    };
  };
}
