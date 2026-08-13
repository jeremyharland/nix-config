{ pkgs, username, ... }:

let
  # U+E0B0, the powerline right-facing triangle. Written as a JSON escape and
  # decoded rather than pasted in as a literal glyph: it is a Private Use Area
  # codepoint, so it renders as a blank box (or gets silently dropped) in any
  # editor without a Nerd Font loaded. This way the source stays plain ASCII.
  powerlineSep = builtins.fromJSON ''"\ue0b0"'';

  jsonFormat = pkgs.formats.json { };
in
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
    awscli2
    zoxide # replaces the brew-installed `z`

    # tmuxifier is NOT a tmux plugin in nixpkgs (there is no
    # tmuxPlugins.tmuxifier) — it is a standalone tool, so it belongs here
    # rather than in programs.tmux.plugins below. tmux itself is not listed:
    # programs.tmux adds its own package.
    tmuxifier

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

    # Must be set before oh-my-zsh is sourced (.zshenv loads before .zshrc).
    # Without this, compinit warns about insecure Nix store paths in $fpath
    # and prompts interactively on every new terminal.
    envExtra = ''
      ZSH_DISABLE_COMPFIX=true
    '';

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

      # tmuxifier. The old line prepended
      # ~/.config/tmux/plugins/tmuxifier/bin to PATH — that directory was a TPM
      # checkout, and TPM is gone (see programs.tmux). tmuxifier now comes from
      # home.packages, so it is already on PATH and only needs activating.
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
  # tmux — replaces the hand-written ~/.config/tmux/tmux.conf.
  # ---------------------------------------------------------------
  # The old config ended with `run '/opt/homebrew/opt/tpm/share/tpm/tpm'`,
  # i.e. plugins came from TPM via the Homebrew `tpm` formula. That is dropped
  # here: home-manager wires each plugin's rtp directly, so there is no TPM, no
  # `brew install tpm` on a new machine, and no `prefix + I` bootstrap step.
  # Note there is no `tpm` in nixpkgs at all under this pin — neither
  # `pkgs.tpm` nor `pkgs.tmuxPlugins.tpm` — so the note in darwin.nix about
  # bringing it back that way does not work.
  #
  # ORDERING, which is easy to get wrong: home-manager assembles tmux.conf as
  #   mkBefore (generated options)  ->  plugins  ->  mkAfter (extraConfig)
  # so plugins load BEFORE extraConfig. Anything a plugin reads at load time
  # must go in that plugin's own `extraConfig`, not the top-level one.
  programs.tmux = {
    enable = true;

    prefix = "C-Space"; # emits the unbind C-b / set prefix / send-prefix trio
    mouse = true;
    keyMode = "vi";
    baseIndex = 1; # sets both base-index and pane-base-index

    # The old config never set these, which meant tmux-sensible's values took
    # effect (it only writes when a setting is still at the tmux default).
    # home-manager writes its own defaults AFTER sensible runs, so leaving
    # these out would silently regress to escape-time 10 / history-limit 2000.
    escapeTime = 0;
    historyLimit = 50000;

    # home-manager defaults this to "screen" (8 colour) — a regression from
    # what sensible was setting. The terminal-overrides line below adds truecolour.
    terminal = "screen-256color";

    # Same trap as escapeTime/historyLimit: home-manager writes these AFTER
    # sensible has run, so its defaults silently undo sensible.
    #   focusEvents      - sensible sets `focus-events on` unconditionally;
    #                      home-manager's default would turn it back off, which
    #                      breaks vim/neovim autoread and FocusGained.
    #   aggressiveResize - sensible sets it on for non-iTerm terminals
    #                      (Ghostty/kitty here), home-manager defaults it off.
    #   clock24          - tmux's own default is 24; home-manager defaults to
    #                      12, which is a change the old config never asked for.
    focusEvents = true;
    aggressiveResize = true;
    clock24 = true;

    # Loads tmux-sensible first, so every explicit setting here wins over it.
    # Because of this, `sensible` is deliberately NOT in the plugins list —
    # listing it as well would run the plugin twice.
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator

      {
        # Upstream catppuccin/tmux. The old config used the
        # dreamsofcode-io/catppuccin-tmux FORK, which is not packaged; the
        # status bar is styled differently as a result. Flavour must be set
        # before the plugin loads, hence the per-plugin extraConfig.
        #
        # Note the spelling: v2.x renamed this from @catppuccin_flavour to
        # @catppuccin_flavor. The British spelling is silently ignored — you
        # still get mocha, but only because that is the packaged default, so
        # picking any other flavour with the old name would appear to do nothing.
        plugin = catppuccin;
        extraConfig = ''
          # Match macOS system appearance at startup / config reload.
          # The hook in extraConfig re-applies this automatically on focus.
          if-shell "defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark" \
            'set -g @catppuccin_flavor "mocha"' \
            'set -g @catppuccin_flavor "latte"'
        '';
      }

      # Binds `y` in copy-mode-vi to copy to the macOS system clipboard.
      # See the note in extraConfig below — do not re-bind `y` there.
      yank
    ];

    extraConfig = ''
      # Truecolour passthrough
      set-option -sa terminal-overrides ",xterm*:Tc"

      set-option -g renumber-windows on

      bind r source-file ~/.config/tmux/tmux.conf \; display "config reloaded"

      # `keyMode = "vi"` above sets BOTH mode-keys and status-keys. The old
      # config only ever set mode-keys, leaving the command prompt (prefix + :)
      # on sensible's deliberate emacs bindings. Restored here so prefix + :
      # keeps behaving the way it does today.
      set -g status-keys emacs

      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Copy mode. The old config also had
      #   bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # but it sat ABOVE the tpm line, so tmux-yank's `y` (copy to system
      # clipboard) overrode it. Here extraConfig lands after the plugins, so
      # re-adding that bind would beat tmux-yank and quietly stop `y` reaching
      # the macOS clipboard. Left out on purpose — yank owns `y`.
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # Splits inherit the current pane's directory
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Re-sync catppuccin flavor to macOS appearance whenever tmux gains focus.
      # The script is written by home.file below; it only re-sources catppuccin
      # when the appearance has actually changed, so it's cheap on every focus.
      set-hook -g client-focus-in "run-shell ~/.config/tmux/theme-sync.sh"
    '';
  };

  # ---------------------------------------------------------------
  # Terminal appearance
  # ---------------------------------------------------------------
  # Both terminals are installed as casks (darwin.nix), so only their config is
  # managed here. Deliberately NOT using programs.ghostty / programs.kitty:
  # those modules install their own copy of the terminal from nixpkgs, which
  # would sit alongside the cask.
  #
  # Ghostty on macOS reads its config from Application Support, not ~/.config —
  # which is why this was missed by the original inventory sweep.
  # Suppresses the "Last login: ..." banner macOS prints on every new terminal.
  home.file.".hushlogin".text = "";

  home.file."Library/Application Support/com.mitchellh.ghostty/config".text = ''
    # Follow the macOS system appearance. Run `ghostty +list-themes` to browse,
    # or `ghostty +show-config` to check what's actually loaded.
    theme = light:Catppuccin Latte,dark:Catppuccin Mocha

    # Match the window chrome (titlebar, tab bar) to the system appearance too.
    window-theme = auto
  '';

  # Syncs the catppuccin tmux flavor to the macOS system appearance.
  # Called via the client-focus-in hook in programs.tmux.extraConfig above.
  # The nix store path for catppuccin_tmux.conf is interpolated at build time
  # so the script always references the currently-active generation's plugin.
  home.file.".config/tmux/theme-sync.sh" = {
    executable = true;
    text =
      let
        catppuccinConf = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin_tmux.conf";
      in
      ''
        #!/usr/bin/env bash
        appearance=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
        if [ "$appearance" = "Dark" ]; then flavor="mocha"; else flavor="latte"; fi
        current=$(tmux show-option -gv @catppuccin_flavor 2>/dev/null)
        if [ "$current" != "$flavor" ]; then
          tmux set -g @catppuccin_flavor "$flavor"
          tmux source "${catppuccinConf}"
        fi
      '';
  };

  # kitty is barely used, but this preserves the old config rather than losing it.
  xdg.configFile."kitty/kitty.conf".text = ''
    dynamic_background_opacity yes
    allow_remote_control yes
    background_opacity 0.5
  '';

  # ---------------------------------------------------------------
  # Claude Code status line (ccstatusline)
  # ---------------------------------------------------------------
  # Only the *status line* config is managed here. ~/.claude/settings.json is
  # deliberately NOT managed — Claude Code writes to it itself (theme,
  # editorMode, model, enabledPlugins all live there and are rewritten by
  # /config, /model and plugin installs), so a read-only /nix/store symlink
  # would break those writes. A snapshot is in inventory/claude-settings.json;
  # copy the `statusLine` block across by hand on a new machine.
  #
  # ccstatusline itself is not in nixpkgs. It stays as `npx -y
  # ccstatusline@latest`, which resolves node from mise (20.13.1) — consistent
  # with the "mise stays" decision above, but it does mean the status line is
  # silently blank until mise is installed and the npx cache is warm.
  #
  # TRADE-OFF worth knowing: this file is now a store symlink, so the
  # `npx ccstatusline` TUI can no longer save changes to it. Edit the attrset
  # below and `rebuild` instead of using the TUI's config editor.
  xdg.configFile."ccstatusline/settings.json".source =
    jsonFormat.generate "ccstatusline-settings.json" {
      version = 3;

      # Each inner list is one rendered row. The `id` values are ccstatusline's
      # own widget keys and only need to be unique — the short numeric ones on
      # row 1 predate the UUIDs it generates now, and are kept as-is rather
      # than renumbered, so this matches what the TUI last wrote.
      lines = [
        [
          { id = "1"; type = "model"; color = "cyan"; }
          { id = "3"; type = "context-length"; color = "brightBlack"; }
          { id = "5"; type = "git-branch"; color = "magenta"; }
          { id = "7"; type = "git-changes"; color = "yellow"; }
        ]
        [
          { id = "44389939-9675-424f-96ab-347e2fed6d39"; type = "tokens-input"; backgroundColor = "bgBrightMagenta"; }
          { id = "0a2071df-0612-4d33-9821-40c89811f0fd"; type = "tokens-output"; backgroundColor = "bgBrightCyan"; }
          { id = "262a13f8-77ef-4552-a2f8-204f547d5f4d"; type = "tokens-total"; backgroundColor = "bgWhite"; }
        ]
        [
          { id = "cc8f1a96-e432-47ae-b414-ae018606e545"; type = "session-usage"; backgroundColor = "bgBlue"; }
          { id = "05cc4faa-0132-4ba4-b9e0-3ed6a1b26852"; type = "session-cost"; backgroundColor = "bgYellow"; }
        ]
      ];

      flexMode = "full-minus-40";
      compactThreshold = 60;
      colorLevel = 2; # 2 = 256 colour; the powerline theme below needs >= 2
      inheritSeparatorColors = false;
      globalBold = false;
      gitCacheTtlSeconds = 5;
      minimalistMode = false;
      defaultPadding = " ";

      powerline = {
        enabled = true;
        separators = [ powerlineSep ];
        separatorInvertBackground = [ false ];
        startCaps = [ ];
        endCaps = [ ];
        autoAlign = false;
        continueThemeAcrossLines = false;
        theme = "nord-aurora";
      };

      # ccstatusline records how it was installed so it knows whether it may
      # self-update. Carried over verbatim: changing it would make the tool
      # try to rewrite this now-read-only file on the next launch.
      installation = {
        method = "auto-update";
        packageManager = "npm";
      };
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
  # Copy ~/.ssh/config across by hand. A snapshot is in
  # inventory/ssh-config.txt — note that without its `IdentityAgent` line,
  # SSH cannot reach the 1Password agent, so `git clone git@github.com:...`
  # fails on a fresh machine. That's a chicken-and-egg: you need it before you
  # can clone this repo over SSH.
  #
  # programs.ssh = { ... };
}
