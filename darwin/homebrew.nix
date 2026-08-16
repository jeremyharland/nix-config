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

    casks = [
      "1password"
      "bruno"
      "caffeine"
      "calibre"
      "chromium"
      "dbeaver-community"
      "discord"
      "figma"
      "firefox@developer-edition"
      "ghostty"
      "google-chrome"
      "intellij-idea"
      "jellyfin-media-player"
      "keybase"
      "logi-options+"
      "maccy"
      "mpv"
      "notion"
      "orbstack"
      "rectangle"
      "signal"
      "slack"
      "spotify"
      "stats"
      "steam"
      "superwhisper"
      "tailscale-app"
      "tor-browser"
      "visual-studio-code"
      "vlc"
      "webtorrent"
    ];

    brews = [ ];

    masApps = {
      "Xcode" = 497799835;
    };
  };
}
