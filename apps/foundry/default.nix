{pkgs, ...}: let
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
in
  pkgs.rustPlatform.buildRustPackage {
    pname = cargoToml.package.name;
    version = cargoToml.package.version;

    src = pkgs.lib.cleanSource ./.;
    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.pkg-config];
    buildInputs = [pkgs.gtk4 pkgs.libadwaita];

    meta = {
      description = cargoToml.package.description;
      mainProgram = "hamra-control";
    };
  }
