{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    claude-code
    htop
    gh
    lazygit
    lazydocker
    mise
    ripgrep
    _1password-cli
    fastfetch
    speedtest-cli
    wget
    eza
    zsh-completions
  ];
}
