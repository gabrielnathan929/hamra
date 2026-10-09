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
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nix-software-center = {
      url = "github:snowfallorg/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
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
        specialArgs = {inherit hamraLib hostName inputs self;};
        modules = [
          ./hosts/${hostName}/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          inputs.noctalia-greeter.nixosModules.default
          inputs.silent-sddm.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          inputs.spicetify-nix.nixosModules.spicetify
          {
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
          }
          {nixpkgs.overlays = [inputs.helium.overlays.default];}
          {
            system.configurationRevision = self.rev or self.dirtyRev or null;
          }
        ];
      };
  in {
    formatter.${system} = pkgs.alejandra;

    devShells = import ./flake/devshell.nix {inherit pkgs system;};
    apps = import ./flake/apps.nix {inherit pkgs system self;};
    packages = import ./flake/packages.nix {inherit pkgs system;};
    nixosConfigurations = import ./flake/hosts.nix {inherit mkHost;};
  };
}
