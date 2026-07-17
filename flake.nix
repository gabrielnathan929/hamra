{
  description = "Hamra - Configuracao NixOS e Home Manager";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.0.0-beta.3";
    };

    silent-sddm = {
      url = "github:gabrielnathan929/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    hamraLib = import ./modules/lib {inherit lib;};

    mkHost = hostName:
      lib.nixosSystem {
        specialArgs = {inherit self inputs hostName hamraLib;};
        modules = [
          ./hosts/${hostName}/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          inputs.silent-sddm.nixosModules.default
          inputs.spicetify-nix.nixosModules.spicetify
          {nixpkgs.overlays = [inputs.helium.overlays.default];}
        ];
      };
  in {
    formatter.${system} = pkgs.alejandra;

    devShells = import ./flake/devshell.nix {inherit pkgs system;};
    apps = import ./flake/apps.nix {inherit pkgs system self;};
    nixosConfigurations = import ./flake/hosts.nix {inherit mkHost;};
  };
}
