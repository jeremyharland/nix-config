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
    # Pre-migration file, previously untracked and unmanaged (programs.starship
    # in home/shell.nix has no `settings`, so home-manager never wrote this
    # path). Adopted here so it's reproducible like everything else.
    "starship.toml" = mkHomeFile "starship.toml";
    # Declares the "npm:ccstatusline" mise tool (installs the binary the
    # Claude Code statusLine command below shells out to) plus node/erlang.
    "mise/config.toml" = mkHomeFile "mise/config.toml";
    # ccstatusline's own segment/layout config, edited via its interactive
    # TUI (`ccstatusline`) -- static once set, unlike ~/.claude/settings.json
    # (deliberately left untracked: Claude Code rewrites that one itself at
    # runtime -- autoMode scans, plugin toggles, theme -- so symlinking it
    # into the repo would just be permanent uncommitted diff churn).
    "ccstatusline/settings.json" = mkHomeFile "ccstatusline/settings.json";
  };

  home.file = {
".ssh/config" = mkHomeFile "ssh/config";
  };
}
