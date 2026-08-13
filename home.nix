{ pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # Set once, then leave alone. Not the same as system.stateVersion.
  home.stateVersion = "24.11";

  # ---------------------------------------------------------------
  # User packages — CLI tools you want everywhere.
  # Language toolchains do NOT go here. They go in per-project flakes
  # (templates/) or stay with mise. See MACHINE-NOTES.md.
  # ---------------------------------------------------------------
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq-go
    bat
    eza
    fzf
    tree
    htop
    gh
    lazygit
    lazydocker
    delta
    httpie
    watch
    coreutils
    gnused
    gnugrep
    gawk
    neovim
    tmux
    awscli2
    zoxide # replaces the brew-installed `z`

    # mise stays. It manages a lot more than language runtimes on this
    # machine (fnox, pitchfork, hk, usage, pkl, vault, age, git-cliff...),
    # much of which has no nixpkgs equivalent. See MACHINE-NOTES.md.
    mise
  ];

  # ---------------------------------------------------------------
  # direnv — this is the load-bearing piece of the whole setup.
  # It auto-loads a project's dev shell when you cd into the directory,
  # which is what replaces asdf/mise for *language runtimes*.
  # ---------------------------------------------------------------
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches shells so cd isn't slow
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    # Carried over from the old .zshrc. Note that zsh-autosuggestions and
    # zsh-syntax-highlighting are NOT listed as oh-my-zsh plugins here —
    # the two options above already provide them from nixpkgs.
    oh-my-zsh = {
      enable = true;
      theme = ""; # empty: starship owns the prompt
      plugins = [ "git" ];
    };

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ls = "eza";
      ll = "eza -la --git";
      lt = "eza --tree --level=2";
      cat = "bat";
      g = "git";
      lg = "lazygit";

      # Carried over from the old .zshrc
      vim = "nvim";
      pn = "pnpm";

      # Rebuild the whole machine after editing this repo
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config";
      # Update all flake inputs (nixpkgs, home-manager, nix-darwin)
      update = "nix flake update --flake ~/nix-config";
    };

    # Becomes ~/.zprofile, which home-manager takes over. These two lines were
    # in the pre-Nix ~/.zprofile — the OrbStack one in particular is easy to
    # lose, and losing it breaks the `orb`/`docker` CLI integration. Login
    # shells that aren't interactive never read .zshrc, so brew shellenv is
    # repeated here on purpose rather than only in initContent.
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Added by OrbStack: command-line tools and integration
      source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    initContent = ''
      # Homebrew on Apple Silicon
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # --- carried over from the old .zshrc ---

      # Locally-installed binaries (mise lives here, among others)
      export PATH="$HOME/.local/bin:$PATH"

      # Android SDK
      export ANDROID_HOME="$HOME/Library/Android/sdk"
      export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

      # The old .zshrc prepended keg-only Homebrew paths for postgresql@16 and
      # openjdk@11 here. Neither formula is declared any more, so both lines
      # are gone: JDKs come from mise or a project flake, and psql/pg_config
      # come from pkgs.postgresql in a project dev shell.

      # Rails / macOS fork-safety workarounds
      export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
      export DISABLE_SPRING=1

      export BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"

      # tmuxifier
      export PATH="$HOME/.config/tmux/plugins/tmuxifier/bin:$PATH"
      command -v tmuxifier >/dev/null && eval "$(tmuxifier init -)"

      # Secrets live outside this repo, on purpose. Not in git.
      [ -f ~/.secrets ] && source ~/.secrets

      # mise, then the tools mise installs that need shell activation.
      command -v mise >/dev/null && eval "$(mise activate zsh)"
      # NOTE: the old .zshrc said `fnox activate bash` inside zsh. Preserved
      # verbatim in case that was deliberate — switch to zsh if it wasn't.
      command -v fnox >/dev/null && eval "$(fnox activate bash)"
      command -v pitchfork >/dev/null && eval "$(pitchfork activate zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Nicer git diffs. Set explicitly rather than via the old
  # `programs.git.delta.enable`, whose implicit git integration is deprecated.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # ---------------------------------------------------------------
  # Git — mirrors the old ~/.gitconfig, including 1Password SSH signing.
  # ---------------------------------------------------------------
  programs.git = {
    enable = true;

    # Single `settings` attrset — home-manager renamed userName / userEmail /
    # extraConfig into this. Keys map straight onto git config sections.
    settings = {
      user = {
        name = "jeremyharland";
        email = "jeremy.harland@gmail.com";

        # Commit signing via the 1Password SSH agent. This is a PUBLIC key —
        # the private half never leaves 1Password, which is why there is
        # nothing in ~/.ssh to copy to the new machine.
        signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfguAGDkLgRwurmbo/fS5+A7rXVCK5mkuJX6tfiH3PD";
      };

      alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      fetch.prune = true;
      diff.colorMoved = "default";

      commit.gpgsign = true;
      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };

    ignores = [
      ".DS_Store"
      ".direnv/"
      ".envrc.local"
      "result"
      "result-*"

      # Carried over from the pre-Nix ~/.config/git/ignore
      "**/.claude/settings.local.json"
    ];
  };

  # ---------------------------------------------------------------
  # SSH — deliberately NOT managed by home-manager.
  # ---------------------------------------------------------------
  # ~/.ssh/config on this machine has ordering constraints home-manager
  # would not respect: OrbStack and colima `Include` lines must appear
  # before any Host block. Authentication is via the 1Password SSH agent
  # (IdentityAgent), so there are no key files to declare either.
  #
  # Copy ~/.ssh/config across by hand — see inventory/ for a snapshot.
  #
  # programs.ssh = { ... };
}
