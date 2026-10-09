{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "foundry";
  version = "0.1.0";
  dontUnpack = true;

  nativeBuildInputs = [pkgs.makeWrapper];

  installPhase = ''
    mkdir -p $out/share/foundry $out/bin
    cp ${./main.js} $out/share/foundry/main.js

    makeWrapper ${pkgs.gjs}/bin/gjs \
      $out/bin/foundry \
      --add-flags "$out/share/foundry/main.js"
  '';

  meta = {
    description = "Foundry — shape your NixOS machine visually";
    mainProgram = "foundry";
  };
}
