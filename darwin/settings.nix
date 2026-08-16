{ ... }:
{
  # Captured from this Mac's live System Settings (defaults read ...) so a
  # fresh machine ends up configured the same way after darwin-rebuild.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      InitialKeyRepeat = 25;
      KeyRepeat = 5;
      "com.apple.swipescrolldirection" = false; # natural scroll off
      _HIHideMenuBar = false;
    };

    menuExtraClock = {
      IsAnalog = false;
      Show24Hour = true;
      ShowDate = 2;
      ShowDayOfWeek = false;
    };

    controlcenter = {
      Bluetooth = false;
      Sound = false;
    };

    dock = {
      autohide = true;
      mru-spaces = false; # don't rearrange Spaces by recent use
      show-recents = false;
      static-only = false; # false = persistent-apps stay pinned when closed
      tilesize = 25;
      persistent-apps = [
        "/Applications/Ghostty.app"
        "/Applications/Firefox Developer Edition.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Slack.app"
      ];
    };

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = false;
      FXPreferredViewStyle = "Nlsv"; # list view
    };

    trackpad = {
      Clicking = false; # tap to click off
      Dragging = false;
      TrackpadThreeFingerDrag = false;
    };

    screencapture.type = "jpg";

    CustomUserPreferences.NSGlobalDomain = {
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
    };

    # Spotlight keeps its own menu-bar-visibility key outside the
    # controlcenter domain (and nix-darwin has no typed option for it).
    CustomUserPreferences."com.apple.Spotlight" = {
      MenuItemHidden = true;
    };
  };
}
