{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    bat
    claude-code
    opencode
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
    inputs.meridian.packages.${pkgs.system}.meridian
  ];
}
