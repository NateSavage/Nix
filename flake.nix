{
  description = "Nate's personal NixOS mono-flake.";

  inputs = {
    # Nix ecosystem
    hardware.url = "github:nixos/nixos-hardware";
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.follows = "nixos-cosmic/nixpkgs";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Secrets Management
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop Environment
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";

	  # Additional flake dependencies
	  nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    impermanence.url = "github:misterio77/impermanence";
    superfile.url = "github:yorukot/superfile";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    home-manager-unstable,
    nixos-cosmic,
    nix-flatpak,
    systems,
    ...
  } @inputs: let
    inherit (self) outputs;
    # lib is a nix convention for where to put helper functions
    lib = nixpkgs.lib // home-manager.lib;
    lib-unstable = nixpkgs-unstable.lib // home-manager-unstable.lib;

    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs (import systems) (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
    unstablePkgsFor = lib-unstable.genAttrs (import systems) (
      system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        }
    );
    pkgs-unstable = unstablePkgsFor.x86_64-linux;

  in {

    inherit lib;
    # locations of things in the flake
    osAppsPath = ./modules/apps;
    osServicesPath = ./modules/services;
    osFeaturesPath = ./modules/feature-sets;
    usersPath = ./users;
    hostsPath = ./hosts;



    #nixosModules = import ./modules/nixos;
    #homeManagerModules = import ./modules/home-manager;
    #overlays = import ./overlays {inherit inputs outputs;};

    # Accessible through 'nix build', 'nix shell', etc
    #packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    #devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {

      # Windows Subsystem for Linux playground.
      whisp = lib.nixosSystem {
        modules = [./hosts/whisp/configuration.nix];
        specialArgs = {inherit inputs outputs;};
      };

      ## Personal Server.
      nox = lib.nixosSystem {
        modules = [./hosts/nox/configuration.nix];
        specialArgs = {inherit inputs outputs;};
      };

      ## Personal Server.
      snek = lib.nixosSystem {
        modules = [
          ./hosts/snek/configuration.nix
          nixos-cosmic.nixosModules.default
          {
            nix.settings = {
              substituters = [ "https://cosmic.cachix.org/" ];
              trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
            };
          }
        ];
        specialArgs = { inherit inputs outputs; };
      };

    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {

      "nate@whisp" = lib.homeManagerConfiguration {
        modules = [ ./home/nate/at/whisp.nix ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };

      "nate@nox" = lib.homeManagerConfiguration {
        modules = [ ./home/nate/at/nox.nix ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };

      "nate@snek" = lib.homeManagerConfiguration {
        modules = [ ./home/nate/at/snek.nix
        #  (inputs.home-manager-unstable + "/modules/programs/zed-editor.nix")
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
      };
    };
  };
}
