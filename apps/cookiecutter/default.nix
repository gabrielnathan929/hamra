{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "cookiecutter";
  version = "0.1.0";
  dontUnpack = true;

  nativeBuildInputs = [pkgs.makeWrapper];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${./cookiecutter.sh} $out/bin/cookiecutter \
      --prefix PATH : ${
      pkgs.lib.makeBinPath [
        pkgs.bash
        pkgs.fzf
        pkgs.git
        pkgs.gum
        pkgs.jq
        pkgs.nix
        pkgs.python3
      ]
    }
  '';

  meta = {
    description = "CookieCutter — shape a new Hamra machine from a template";
    mainProgram = "cookiecutter";
  };
}
