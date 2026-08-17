{ ... }:
{
  # Casks/apps specific to the personal machine, on top of the common list
  # in darwin/homebrew.nix. list-typed options merge across modules, so
  # this just adds to that list rather than replacing it.
  homebrew.casks = [
    "calibre"
    "jellyfin-media-player"
    "signal"
    "spotify"
    "steam"
    "tor-browser"
    "webtorrent"
  ];

  # Requires being signed into the App Store with a personal Apple ID.
  homebrew.masApps = {
  };
}
