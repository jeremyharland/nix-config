{ ... }:
{
  # Casks/apps specific to the work laptop, on top of the common list in
  # darwin/homebrew.nix. Starting empty — fill in with whatever this
  # machine actually needs (VPN client, work chat app, etc).
  homebrew.casks = [
    "intellij-idea"
  ];
}
