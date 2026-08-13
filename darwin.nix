{ pkgs, username, hostname, ... }:

{
  # ---------------------------------------------------------------
  # Core
  # ---------------------------------------------------------------
  nixpkgs.hostPlatform = "aarch64-darwin"; # match flake.nix
  nixpkgs.config.allowUnfree = true;

  # Bump only when the nix-darwin release notes tell you to.
  # Check `darwin-rebuild changelog` after your first build.
  system.stateVersion = 5;

  # Required by newer nix-darwin for options that target a specific user
  # (defaults, homebrew, etc). If your nix-darwin is older than ~mid-2025
  # this option won't exist — delete the line if evaluation complains.
  system.primaryUser = username;

  # hostName drives LocalHostName, which is what `darwin-rebuild switch` matches
  # against to pick a darwinConfigurations entry — so this must stay in sync
  # with the keys in flake.nix.
  networking.hostName = hostname;

  # computerName deliberately left unmanaged: this machine is "Jeremy's MacBook
  # Pro (2)" in Finder/AirDrop and there's no reason to flatten that to the
  # hostname form.
  # networking.computerName = hostname;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Nix is installed via Determinate, so Determinate owns the daemon and
  # /etc/nix/nix.conf. This option comes from `determinate.darwinModules.default`
  # (wired up in flake.nix) and disables nix-darwin's built-in Nix management
  # for us — which is why `nix.enable = false` is NOT set here. Setting both is
  # the old advice; as of Determinate Nix 3.15.2 this option supersedes it.
  #
  # If you ever switch to the official nixos.org installer: drop the determinate
  # input and module, delete this line, and uncomment the nix.* block below.
  determinateNix.enable = true;

  # ---------------------------------------------------------------
  # Nix settings — via Determinate, not nix-darwin's `nix.settings`.
  # ---------------------------------------------------------------
  # Determinate owns /etc/nix/nix.conf (the module even does
  # `nix.enable = lib.mkForce false` for us), so nix-darwin's `nix.settings` /
  # `nix.gc` / `nix.optimise` are inert here. Custom settings go through
  # `determinateNix.customSettings`, which the module renders into
  # /etc/nix/nix.custom.conf — don't hand-edit that file, it gets overwritten.
  #
  # Determinate already turns on nix-command and flakes and manages its own GC,
  # so all that's left from the original nix.settings block is the community
  # binary cache.
  #
  # A few keys are rejected here by design: bash-prompt-prefix,
  # external-builders, extra-nix-path, netrc-file, ssl-cert-file and
  # upgrade-nix-store-path-url are all Determinate-owned.
  determinateNix.customSettings = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # nix.settings = {
  #   experimental-features = [ "nix-command" "flakes" ];
  #   trusted-users = [ "root" username ];
  #   substituters = [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
  #   trusted-public-keys = [
  #     "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  #     "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  #   ];
  # };
  #
  # nix.optimise.automatic = true;
  # nix.gc = {
  #   automatic = true;
  #   interval.Day = 7;
  #   options = "--delete-older-than 30d";
  # };

  # ---------------------------------------------------------------
  # System packages (things that make sense outside a project shell)
  # ---------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  documentation.enable = false;

  programs.zsh.enable = true; # needed so nix paths land in your shell
  programs.zsh.enableCompletion = false; # home-manager's programs.zsh handles compinit; this prevents double init

  # ---------------------------------------------------------------
  # Homebrew — declarative, for GUI apps and things Nix does badly
  # ---------------------------------------------------------------
  # NOTE: nix-darwin does NOT install Homebrew. Install it once by hand,
  # then this block manages what's in it.
  # This list was generated from `brew leaves` / `brew list --cask` on
  # Jeremys-MacBook-Pro-2 on 2026-08-13. Raw capture: inventory/Brewfile.
  homebrew = {
    enable = true;

    onActivation = {
      # Both deliberately off. With them on, every `darwin-rebuild switch`
      # upgrades all 42 formulae and 27 casks — including postgresql@14/@16,
      # where a major bump can leave existing data directories unreadable.
      # Not something to trigger implicitly on a machine you depend on.
      # Run `brew upgrade` by hand when you actually want it; consider
      # turning these on once the new machine is the only one in use.
      autoUpdate = false;
      upgrade = false;

      # "zap" removes anything not listed here. Left at "none" until this
      # list has been verified against a real build — see README Phase 5.
      cleanup = "none";
    };

    # No taps needed. All three the old machine had are gone:
    #   homebrew/services  merged into Homebrew core years ago; `brew tap-info`
    #                      reports "No commands/casks/formulae" for it, and
    #                      `brew services` works as a built-in command
    #   minio/stable       orphaned — the tap was present but nothing was ever
    #                      installed from it
    #   nikitabobko/tap    existed only to provide the aerospace cask
    taps = [ ];

    # Homebrew keeps only what it is genuinely better at than Nix:
    # Xcode-coupled tooling and launchd-managed database servers.
    #
    # Deliberately NOT here, so the new machine starts clean (all of this was
    # on the old one — see inventory/brew-leaves.txt if you need to look
    # something up):
    #   openjdk@11, openjdk@17  -> mise already has temurin-21/25 and zulu-17
    #   automake, libffi, openssl@1.1, vips, zlib
    #                           -> build deps; belong in per-project dev shells
    #                              (templates/ruby.nix already declares them)
    #   colima                  -> redundant, OrbStack is the container runtime
    #   openvpn, pipenv, python-setuptools
    #                           -> Nix or mise if they turn out to be needed
    #   tpm                     -> not needed, and pkgs.tmuxPlugins.tpm does not
    #                              exist under this nixpkgs pin. tmux plugins are
    #                              declared in programs.tmux.plugins (home.nix),
    #                              which wires each plugin's rtp directly — there
    #                              is no TPM and no `prefix + I` bootstrap.
    #   postgresql@14, @16      -> per-project dev shells (templates/ruby.nix
    #                              declares pkgs.postgresql, which supplies both
    #                              pg_config for native gems and the psql client)
    #                              or a container via OrbStack
    # Everything CLI-shaped (bat, fzf, gh, jq, ripgrep, neovim, awscli2, ...)
    # is in home.packages instead.

    casks = [
      "1password"
      "1password-cli"
      "bruno"
      "claude"
      "chromium"
      "dbeaver-community"
      "figma"
      "firefox@developer-edition"
      "font-hack-nerd-font"
      "ghostty"
      "google-chrome"
      "intellij-idea"
      "maccy"
      "orbstack" # Docker/K8s runtime — replaces Docker Desktop
      "notion"
      "rectangle"
      "signal"
      "slack"
      "spotify"
      "stats"
      "superwhisper"
      "tailscale-app"
      "visual-studio-code"
      "vlc"
      "wireshark-app"
    ];

    masApps = {
      # "Xcode" = 497799835;
    };
  };

  # ---------------------------------------------------------------
  # macOS system defaults
  # ---------------------------------------------------------------
  system.defaults = {
    dock = {
      autohide = false;
      show-recents = false;
      mru-spaces = false;
      tilesize = 36;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false; # key repeat instead of accent menu
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.swipescrolldirection" = false; # natural scroll off
    };

    trackpad.Clicking = true;
  };

  # Touch ID for sudo. On newer nix-darwin this is the sudo_local form;
  # older versions used `security.pam.enableSudoTouchIdAuth = true;`
  security.pam.services.sudo_local.touchIdAuth = true;
}
