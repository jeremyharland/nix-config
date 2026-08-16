{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
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
    fastfetch
    speedtest-cli
    wget
    eza
    zsh-completions
  ];
}
