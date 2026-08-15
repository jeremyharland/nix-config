{ ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "jeremy";
        email = "jeremy.harland@gmail.com";
      };

      alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      init.defaultBranch = "main";
    };
  };
}
