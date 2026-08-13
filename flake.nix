{
  description = "Darwin + home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate's own nix-darwin module. Setting `determinateNix.enable`
    # (see darwin.nix) turns off nix-darwin's built-in Nix management, which
    # is what stops the two fighting over the daemon and /etc/nix/nix.conf.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, determinate, ... }:
    let
      username = "jeremyharland";
      system = "aarch64-darwin"; # "x86_64-darwin" on Intel

      mkHost = hostname: nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username hostname; };

        modules = [
          determinate.darwinModules.default
          ./darwin.nix

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit username; };
              users.${username} = import ./home.nix;

              # Rather than aborting when a pre-Nix dotfile is in the way,
              # move it aside to <name>.hm-backup. Without this the first
              # activation fails on every hand-written file it wants to own
              # (.zprofile, .config/git/ignore, ...) one error at a time.
              backupFileExtension = "hm-backup";
            };
          }
        ];
      };
    in
    {
      # `darwin-rebuild switch --flake ~/nix-config` selects the entry matching
      # `scutil --get LocalHostName`. Both machines are defined here so the same
      # repo builds on either one without editing.
      darwinConfigurations = {
        # Current machine — the one being migrated away from.
        "Jeremys-MacBook-Pro-2" = mkHost "Jeremys-MacBook-Pro-2";

        # New MacBook. Either rename this key to match its LocalHostName, or
        # set the new machine's name to this and it will just work:
        #   sudo scutil --set LocalHostName jeremy-macbook
        "jeremy-macbook" = mkHost "jeremy-macbook";
      };

      # Convenience so `nix fmt` and `nix flake check` behave
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
