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
      ];

      shellHook = ''
        echo "alejandra  -> nix fmt"
        echo "statix     -> linter"
        echo "deadnix    -> codigo morto"
        echo "nix run .#deploy <host> -> valida + switch"
        echo "nix run .#build <host>  -> build sem aplicar"
      '';
    };
  };
}
