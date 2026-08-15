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
      username = "jeremy";
      system = "aarch64-darwin";

      mkHost = hostname: nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs self username hostname; };

        modules = [
          ./darwin
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
      # whose name matches `scutil --get LocalHostName`. Adding a machine is a
      # one-line change here — see darwin/default.nix for what stays in sync.
      darwinConfigurations = nixpkgs.lib.genAttrs [
        "Jeremys-MacBook-Pro" # scutil --get LocalHostName on this machine
      ] mkHost;

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
