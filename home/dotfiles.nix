{ config, ... }:
let
  # Out-of-store symlinks point straight at the cloned repo instead of a
  # /nix/store path, so editing a tracked file takes effect immediately —
  # no `darwin-rebuild switch` round-trip, and no GNU Stow needed either.
  repoRoot = "${config.home.homeDirectory}/.config/nix-config/dotfiles";
  mkSource = repoRel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${repoRel}";
  mkHomeFile = repoRel: { source = mkSource repoRel; };
in
{
  # dotfiles/nvim is a vendored config (NvChad-based); this just makes sure
  # the nvim binary itself is installed and the default editor.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  xdg.configFile = {
    "nvim" = mkHomeFile "nvim";
    "ghostty" = mkHomeFile "ghostty";
  };

  home.file = {
    # Leaf-level only: ~/superwhisper also holds models/ and recordings/,
    # real untracked data that a whole-directory symlink would shadow.
    "superwhisper/settings/settings.json" = mkHomeFile "superwhisper/settings/settings.json";
    "superwhisper/modes/default.json" = mkHomeFile "superwhisper/modes/default.json";
    ".ssh/config" = mkHomeFile "ssh/config";
  };
}
