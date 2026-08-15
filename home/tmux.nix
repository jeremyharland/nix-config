{ pkgs, ... }:
let
  # Polls macOS appearance and flips the catppuccin flavor live so tmux
  # keeps following light/dark after startup (a plain if-shell only picks
  # the flavor once, at tmux start).
  #
  # catppuccin's own option defaults are `set -og` (only-if-unset), so once
  # a module color/status string is baked from the first flavor it loaded
  # under, simply re-running the plugin script does NOT recompute it for a
  # new flavor -- status bar stays lit for whichever flavor came first. So
  # every @catppuccin_* global is unset before re-running the plugin, forcing
  # it to rebuild the whole option tree from scratch for the new flavor.
  systemThemeWatcher = pkgs.writeShellScript "tmux-system-theme-watcher" ''
    last=""
    while true; do
      if [ "$(/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
        current="mocha"
      else
        current="latte"
      fi
      if [ "$current" != "$last" ]; then
        ${pkgs.tmux}/bin/tmux show-options -g | awk '/^@(catppuccin|thm|batt|cpu)_/{print $1}' | while read -r opt; do
          ${pkgs.tmux}/bin/tmux set-option -gu "$opt"
        done
        ${pkgs.tmux}/bin/tmux set-option -g @catppuccin_flavor "$current"
        ${pkgs.tmux}/bin/tmux run-shell "${pkgs.tmuxPlugins.catppuccin.rtp}"
        last="$current"
      fi
      sleep 5
    done
  '';
in
{
  # Replaces the old hand-written tmux.conf + TPM checkout (which was three
  # orphaned git submodule gitlinks with no .gitmodules — plugins only ever
  # loaded if `~/.config/tmux/plugins/tpm` happened to already exist).
  # home-manager wires each plugin's rtp directly: no TPM, no brew/git
  # bootstrap step, no `prefix + I`.
  programs.tmux = {
    enable = true;

    mouse = true;
    prefix = "C-Space"; # emits unbind C-b / set prefix / send-prefix
    keyMode = "vi";
    baseIndex = 1; # sets both base-index and pane-base-index

    # home-manager writes its own defaults for these AFTER tmux-sensible
    # runs (sensibleOnTop below), silently undoing sensible's values if left
    # unset — so they're pinned explicitly to what sensible would set.
    escapeTime = 0;
    focusEvents = true;

    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank

      {
        # Upstream catppuccin/tmux (not the dreamsofcode-io fork the old
        # config referenced — that one isn't packaged). Flavor must be set
        # before the plugin loads.
        plugin = catppuccin;
        extraConfig = ''
          # Match macOS light/dark appearance at startup; systemThemeWatcher
          # (below) keeps it in sync afterward.
          if-shell '[ "$(/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]' \
            'set -g @catppuccin_flavor "mocha"' \
            'set -g @catppuccin_flavor "latte"'
        '';
      }
    ];

    extraConfig = ''
      set-option -sa terminal-overrides ",xterm*:Tc"
      set-option -g renumber-windows on

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

      # copy-mode-vi y is bound explicitly here (lands after the yank
      # plugin loads, so this wins) to match the old config's behavior.
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      run-shell -b "${systemThemeWatcher}"
    '';
  };
}
