{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    bruno
    claude-code
    fzf
    htop
    gh
    lazygit
    lazydocker
    mise
    ripgrep
    zoxide
    _1password-cli
    _1password-gui
    mpv
    fastfetch
    speedtest-cli
    wget
    eza
    zsh-completions
  ];
}
