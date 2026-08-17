{ gitUser, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = gitUser;

      alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      init.defaultBranch = "main";

      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfguAGDkLgRwurmbo/fS5+A7rXVCK5mkuJX6tfiH3PD";
      gpg.format = "ssh";
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      commit.gpgsign = true;
    };
  };
}
