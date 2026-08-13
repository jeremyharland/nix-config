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

  networking.hostName = hostname;
  networking.computerName = hostname;

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
  # Nix settings: deliberately NOT managed here.
  # ---------------------------------------------------------------
  # Determinate owns nix.conf, so the `nix.settings` / `nix.gc` /
  # `nix.optimise` options below would be inert. Determinate already enables
  # flakes and nix-command by default and manages its own GC, so most of this
  # is redundant anyway.
  #
  # To add extra substituters under Determinate, put them in
  # /etc/nix/nix.custom.conf (which Determinate leaves alone) instead:
  #
  #   extra-substituters = https://nix-community.cachix.org
  #   extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
  #
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

  programs.zsh.enable = true; # needed so nix paths land in your shell

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
      autoUpdate = true;
      upgrade = true;
      # "zap" removes anything not listed here. Left at "none" until this
      # list has been verified against a real build — see README Phase 5.
      cleanup = "none";
    };

    taps = [
      "homebrew/services"
      "minio/stable"
      "nikitabobko/tap" # aerospace
    ];

    # Kept in Homebrew on purpose: native build deps, iOS/React Native
    # tooling, and database servers. Everything CLI-shaped that Nix handles
    # cleanly has moved to home.packages in home.nix instead.
    brews = [
      # iOS / React Native — these expect a system Ruby and Xcode layout
      "cocoapods"
      "fastlane"
      "watchman"

      # Native gem / build dependencies (see the Ruby note in templates/ruby.nix)
      "automake"
      "libffi"
      "openssl@1.1"
      "vips"
      "zlib"

      # Databases and services, run via `brew services`
      "postgresql@14"
      "postgresql@16"
      "redis"

      # JDKs still referenced by PATH in the old .zshrc — project flakes and
      # mise should own these instead. Drop once nothing depends on them.
      "openjdk@11"
      "openjdk@17"

      # Misc that has no clean Nix equivalent on darwin
      "colima"
      "openvpn"
      "pipenv"
      "python-setuptools"
      "tpm" # tmux plugin manager
    ];

    casks = [
      "1password"
      "1password-cli"
      "aerospace"
      "android-studio"
      "bruno"
      "chromium"
      "dbeaver-community"
      "figma"
      "firefox"
      "font-hack-nerd-font"
      "ghostty"
      "intellij-idea"
      "iterm2"
      "kitty"
      "maccy"
      "ngrok"
      "orbstack" # Docker/K8s runtime — replaces Docker Desktop
      "postman"
      "rectangle"
      "signal"
      "spotify"
      "stats"
      "visual-studio-code"
      "vlc"
      "wireshark-app"
      "zulu@17"
      # "wireshark" — legacy name, superseded by wireshark-app. Both were
      # installed on the old machine; only install one on the new one.
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
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      tilesize = 48;
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
