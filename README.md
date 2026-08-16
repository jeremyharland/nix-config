# nix-config

Personal macOS system configuration: nix-darwin + home-manager + Homebrew,
managed as a flake. Structure modeled on [bgub/nix](https://github.com/bgub/nix).

## Structure

- `flake.nix` — inputs and `darwinConfigurations`, keyed by machine hostname
  (`scutil --get LocalHostName`) so `darwin-rebuild switch --flake .` picks
  the right host automatically, no `#attr` needed. Each entry also points at
  a `hosts/*.nix` module for that machine's own config.
- `darwin/` — system-level config shared by every host: Nix settings, common
  Homebrew casks, macOS defaults, per-app `defaults` preferences.
- `hosts/` — per-machine overrides layered on top of `darwin/`. Currently
  just extra `homebrew.casks`/`masApps` (list-typed options merge across
  modules, so a host file adds to the common list rather than replacing
  it) — `personal.nix` for this Mac, `work.nix` for the work laptop.
- `home/` — home-manager: shell, git, tmux, packages.
- `dotfiles/` — raw config files (nvim, ghostty, superwhisper, ssh) that
  home-manager symlinks into place via `home/dotfiles.nix`, using
  out-of-store symlinks straight into this repo. No GNU Stow: editing a
  tracked file takes effect immediately, no rebuild needed.

## Bootstrap on a fresh Mac

**1. Command Line Tools + Nix (one block, non-interactive)**

CLT is required before anything else: it provides `git` (to clone this
repo) and Homebrew's installer hard-refuses to run without it.

```sh
# Command Line Tools (silent — avoids the GUI popup / manual "Install" click)
if ! xcode-select -p >/dev/null 2>&1; then
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  PROD=$(softwareupdate -l | grep "\*.*Command Line Tools" | tail -n1 | sed 's/^[^C]* //')
  sudo softwareupdate -i "$PROD" --agree-to-license
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

# Nix (official/classic installer). If a machine ever uses the Determinate
# installer instead, see the Gotchas section below before first activation.
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
```

Restart the terminal after this so `nix` is on `PATH`.

**2. Sign into the App Store**

`darwin/homebrew.nix` installs Xcode via `masApps`. `mas` needs an
already-signed-in App Store account or that install silently fails.

**3. Clone**

```sh
git clone git@github.com:jeremyharland/nix-config.git ~/.config/nix-config
cd ~/.config/nix-config
```

**3a. Create `~/.ssh/config.local`**

The tracked `dotfiles/ssh/config` is generic. Anything machine-specific
(public IPs, personal/student IDs) goes in `~/.ssh/config.local`, which
stays outside the repo:

```sh
cat > ~/.ssh/config.local <<'EOF'
Host myserver
  HostName 203.0.113.5
  User someone
EOF
chmod 600 ~/.ssh/config.local
```

**4. Add the machine's hostname**

`flake.nix`'s `darwinConfigurations` attrset must contain this Mac's
`scutil --get LocalHostName` as a key. If this is a new machine (not the
personal MacBook or the work laptop already listed), add an entry pointing
at a new or existing `hosts/*.nix` file. For the work laptop specifically,
just update the placeholder hostname already in `flake.nix` to match
`scutil --get LocalHostName` and fill in `hosts/work.nix` with whatever
casks that machine needs.

**5. Move current bashrc and zshrc**

create a backup of bashrc and zshrc

```sh
mv /etc/bashrc /etc/bashrc.bak
mv /etc/zshrc /etc/zshrc.bak
```

**6. First activation**

`darwin-rebuild` doesn't exist yet on a fresh machine, so the first switch
runs through `nix run`. home-manager's `backupFileExtension = "hm-backup"`
means it moves pre-existing dotfiles aside (`<name>.hm-backup`) instead of
aborting activation.

```sh
sudo nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake ~/.config/nix-config
```

This installs Homebrew itself, all casks/MAS apps, home-manager's zsh +
starship + tmux + dotfile symlinks, and macOS defaults. Takes a while the
first time.

**7. Subsequent changes**

```sh
darwin-rebuild switch --flake ~/.config/nix-config
# or, once home-manager has run once:
rebuild
```

## Gotchas

- **Hostname-keyed, not a fixed name.** `flake.nix`'s `darwinConfigurations`
  is keyed by `LocalHostName`, each entry pointing at a `hosts/*.nix`
  module — no per-machine username edit needed beyond that. `username` is
  still a single `let` binding in `flake.nix` if it ever needs to change.
- **Homebrew casks are common + per-host.** `darwin/homebrew.nix` holds the
  cask list shared by every machine; `hosts/*.nix` adds machine-specific
  casks on top (nix-darwin's `homebrew.casks` is list-typed, so definitions
  across modules concatenate rather than override).
- **Determinate-installed machines.** The classic installer (step 1) lets
  nix-darwin own `/etc/nix/nix.conf` (see `darwin/default.nix`). If a
  machine instead uses the Determinate installer, first activation fails
  with "Determinate detected, aborting activation" — fix is
  `nix.enable = false;` on that host, since Determinate's own daemon
  manages `nix.conf` instead. Not a global default: it would break
  classic-Nix machines' flakes support.
- **Homebrew cleanup is aggressive.** `homebrew.onActivation.cleanup =
  "zap"` in `darwin/homebrew.nix` removes any cask/formula *not* listed in
  that file on every switch, including app data.
- **tmux plugins are nix-native**, not TPM. `home/tmux.nix` declares them
  via `programs.tmux.plugins` — no `prefix + I` bootstrap, no
  `~/.config/tmux/plugins` checkout.
- **nvim config is vendored as-is** (`dotfiles/nvim`, NvChad-based) —
  symlinked whole, not rebuilt through home-manager's `programs.neovim`
  plugin system.
