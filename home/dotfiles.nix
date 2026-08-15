{ config, pkgs, ... }:
let
  # Out-of-store symlinks point straight at the cloned repo instead of a
  # /nix/store path, so editing a tracked file takes effect immediately —
  # no `darwin-rebuild switch` round-trip, and no GNU Stow needed either.
  repoRoot = "${config.home.homeDirectory}/.config/nix-config/dotfiles";
  mkSource = repoRel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${repoRel}";
  mkHomeFile = repoRel: { source = mkSource repoRel; };
in
{
  # dotfiles/nvim is a vendored config (NvChad-based) symlinked whole below.
  # Deliberately NOT using programs.neovim: it writes its own generated
  # .config/nvim/init.lua, which collides with the vendored directory
  # symlink ("Error installing file '.config/nvim/init.lua' outside $HOME").
  # Just the package, plus EDITOR (home/shell.nix already aliases vim=nvim).
  home.packages = [ pkgs.neovim ];
  home.sessionVariables.EDITOR = "nvim";

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
