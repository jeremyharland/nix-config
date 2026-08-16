{
  description = "jeremy's system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }@inputs:
    let
      system = "aarch64-darwin";

      # hostModule carries whatever's specific to one machine (extra
      # Homebrew casks, etc) — see hosts/*.nix. It's just another module,
      # layered on top of the shared ./darwin config. username is per-host
      # too, since it's tied to the macOS account on that machine, not a
      # fixed identity (eg. the work laptop logs in as "JeremyHarland").
      mkHost = { hostname, username, hostModule }: nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs self username hostname; };

        modules = [
          ./darwin
          hostModule
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs self username; };
              users.${username} = import ./home;

              # Move pre-existing dotfiles aside instead of aborting activation
              # on the first switch.
              backupFileExtension = "hm-backup";
            };
          }
        ];
      };
    in
    {
      # `darwin-rebuild switch --flake ~/.config/nix-config` selects the entry
      # whose name matches `scutil --get LocalHostName`. Adding a machine
      # means adding an entry here pointing at a hosts/*.nix file — see
      # darwin/default.nix for what stays in sync.
      darwinConfigurations = {
        "Jeremys-MacBook-Pro" = mkHost {
          hostname = "Jeremys-MacBook-Pro";
          username = "jeremy";
          hostModule = ./hosts/personal.nix;
        };

        # Update the hostname below to match `scutil --get LocalHostName`
        # once set on the actual machine.
        "Jeremys-Work-Laptop" = mkHost {
          hostname = "Jeremys-Work-Laptop";
          username = "JeremyHarland";
          hostModule = ./hosts/work.nix;
        };
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
