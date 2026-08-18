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
  system.defaults.CustomUserPreferences = {
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
