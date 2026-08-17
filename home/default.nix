{ username, ... }:
{
  imports = [
    ./packages.nix
    ./git.nix
    ./mpv.nix
    ./shell.nix
    ./tmux.nix
    ./dotfiles.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "24.05";

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Suppress the "Last login: ..." banner on every new terminal.
  home.file.".hushlogin".text = "";
}
