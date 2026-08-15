{ pkgs, ... }:
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
          set -g @catppuccin_flavor "mocha"
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
    '';
  };
}
