{ pkgs, lib, config, ... }:
{
  programs.zsh = {
    enable = true;
    # compinit's default `compaudit` security scan re-stats every dir in
    # $fpath on every shell start (~600ms here). We run it ourselves in
    # initContent with `compinit -C`, which skips that scan and only
    # re-verifies once a day (see the `mkOrder 600` block below).
    enableCompletion = false;

    defaultKeymap = "emacs";

    shellAliases = {
      # listing
      l = "eza -lh  --icons=auto";
      ls = "eza -1   --icons=auto";
      ll = "eza -lha --icons=auto --sort=name --group-directories-first";
      ld = "eza -lhD --icons=auto";

      # misc
      vim = "nvim";
      pn = "pnpm";
      python = "python3";
      pip = "pip3";
      mkdir = "mkdir -p";

      # navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      ".3" = "cd ../../..";
      ".4" = "cd ../../../..";
      ".5" = "cd ../../../../..";
      docs = "cd ~/Documents";

      # git
      gst = "git status";
      gss = "git status -s";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit -v";
      gcmsg = "git commit -m";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcl = "git clone";
      gb = "git branch";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph --decorate";
      gd = "git diff";
      gds = "git diff --staged";
      grh = "git reset HEAD";
      gsta = "git stash";
      gstp = "git stash pop";

      # gh
      ghpr = "gh pr create";
      ghprv = "gh pr view --web";
      ghprs = "gh pr status";
      ghi = "gh issue list";
      ghr = "gh repo view --web";
      ghc = "gh repo clone";

      # nix
      rebuild = "sudo darwin-rebuild switch --flake ~/.config/nix-config";
      update = "nix flake update --flake ~/.config/nix-config";
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
      BROWSER = "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox";
    };

    # login-shell env, previously in loose ~/.zshenv / ~/.zprofile
    envExtra = ''
      # uv
      export PATH="${config.home.homeDirectory}/.local/bin:$PATH"
    '';
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Added by OrbStack: command-line tools and integration
      # This won't be added again if you remove it.
      source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    initContent = lib.mkMerge [
      # zsh-completions' function definitions need to be in fpath before
      # compinit runs.
      (lib.mkOrder 550 ''
        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
      '')

      # Skip compinit's compaudit security scan unless the dump is >24h
      # old, dropping compinit from ~600ms to ~20ms on every other start.
      (lib.mkOrder 600 ''
        # Case-insensitive completion, e.g. `cd doc<TAB>` matches `Documents`.
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

        autoload -Uz compinit
        zcd="''${ZDOTDIR:-$HOME}/.zcompdump"
        if [[ -n "$zcd"(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
        unset zcd
      '')

      (lib.mkOrder 1000 ''
        # up/down arrow: filter history to lines starting with what's already
        # typed, instead of cycling every history entry (oh-my-zsh core default)
        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "^[[A" up-line-or-beginning-search
        bindkey "^[[B" down-line-or-beginning-search

        command -v mise >/dev/null && eval "$(mise activate zsh)"
      '')
    ];
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
