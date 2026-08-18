{ username, ... }:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap"; # removes anything not listed below on every switch
    };

    taps = [ ];

    # Common to every host. Machine-specific extras live in hosts/*.nix —
    # homebrew.casks is a list-typed option, so per-host modules append to
    # this rather than replacing it.
    casks = [
      "1password"
      "bruno"
      "caffeine"
      "chromium"
      "dbeaver-community"
      "discord"
      "fluidvoice"
      "figma"
      "firefox@developer-edition"
      "ghostty"
      "google-chrome"
      "keybase"
      "logi-options+"
      "maccy"
      "notion"
      "orbstack"
      "rectangle"
      "slack"
      "spotify"
      "stats"
      "tailscale-app"
      "visual-studio-code"
      "vlc"
    ];

    brews = [ ];

    masApps = { 
      "Xcode" = 497799835;
    };
  };
}
