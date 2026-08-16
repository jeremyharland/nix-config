{ pkgs, self, username, hostname, ... }:
{
  imports = [
    ./homebrew.nix
    ./settings.nix
    ./apps.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin"; # match flake.nix
  nixpkgs.config.allowUnfree = true;

  fonts.packages = [ pkgs.nerd-fonts.hack ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Required for options that target a specific user (homebrew, defaults, ...).
  system.primaryUser = username;

  # hostName drives LocalHostName, which darwin-rebuild matches against to
  # pick a darwinConfigurations entry — keep in sync with flake.nix's
  # darwinConfigurations attrset (and its hosts/*.nix module).
  networking.hostName = hostname;

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # This machine's Nix install is the classic/official installer, so
  # nix-darwin owns /etc/nix/nix.conf itself. If a machine is ever installed
  # via the Determinate installer instead, that install hard-aborts
  # activation here ("Determinate detected") — fix is `nix.enable = false;`
  # on that host, since Determinate's own daemon manages nix.conf instead.
  nix.settings.experimental-features = "nix-command flakes";

  programs.zsh.enable = true; # needed so nix paths land in the shell
  # home-manager's programs.zsh (home/shell.nix) handles compinit; this
  # nix-darwin copy would otherwise double-init and cost ~600ms per shell.
  programs.zsh.enableCompletion = false;
  programs.zsh.enableBashCompletion = false;
  programs.zsh.promptInit = "";

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true; # Touch ID inside tmux
  };
}
