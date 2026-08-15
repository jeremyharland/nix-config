{ username, ... }:
{
  launchd.user.agents.stats = {
    serviceConfig = {
      ProgramArguments = [ "/Applications/Stats.app/Contents/MacOS/Stats" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.user.agents.orbstack = {
    serviceConfig = {
      ProgramArguments = [ "/Applications/OrbStack.app/Contents/MacOS/OrbStack" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  # Per-app preferences, captured from live `defaults read <domain>` output.
  # Only meaningful user settings are kept here — internal/runtime state
  # (window frames, timestamps, version strings, telemetry IDs) is left out
  # since it regenerates itself and isn't something you'd want to "restore".
  #
  # Superwhisper's actual config (modes, replacements/vocabulary) is a real
  # dotfile — see dotfiles/superwhisper, symlinked via home/dotfiles.nix.
  system.defaults.CustomUserPreferences = {
    "com.superduper.superwhisper" = {
      launchOnLogin = true;
      showApplicationInDock = false;
      clipboardBehaviour = "bypass";
      enableSoundEffects = true;
      soundEffectTheme = "simple";
      appTheme = "system";
      appFolderDirectory = "/Users/${username}";
      # hotkeys captured as-is from `defaults read com.superduper.superwhisper`
      KeyboardShortcuts_pushToTalk = ''{"carbonKeyCode":49,"carbonModifiers":2048,"mouseButtonNumbers":[]}'';
      KeyboardShortcuts_toggleRecording = ''{"carbonKeyCode":54,"mouseButtonNumbers":[],"carbonModifiers":256}'';
    };

    "org.p0deje.Maccy" = {
      showInStatusBar = false;
      SUEnableAutomaticChecks = false;
      SUSendProfileInfo = false;
      # Cmd+Shift+M to pop up history (carbonKeyCode 46 = M, carbonModifiers 768 = cmd+shift)
      KeyboardShortcuts_popup = ''{"carbonKeyCode":46,"carbonModifiers":768}'';
    };

    "com.knollsoft.Rectangle" = {
      hideMenubarIcon = true;
      launchOnLogin = true;
      reflowTodo = { keyCode = 45; modifierFlags = 786432; };
      toggleTodo = { keyCode = 11; modifierFlags = 786432; };
    };

    "eu.exelban.Stats" = {
      LaunchAtLoginNext = true;
      telemetry = false;

      Battery_widget = "bar_chart";
      Network_widget = "speed";
      Sensors_widget = "";
    };
  };
}
