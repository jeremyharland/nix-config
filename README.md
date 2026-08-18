# nix-config

My personal macOS system configuration: nix-darwin + home-manager + Homebrew,
managed as a flake. Layout modeled on [bgub/nix](https://github.com/bgub/nix).

Published in case it's useful as a reference. It's opinionated to my
machines and workflow — read, don't blindly `switch`. Casks, MAS apps,
macOS defaults, and identities in `flake.nix` are all mine.

## Structure

- `flake.nix` — inputs and `darwinConfigurations`, keyed by machine
  hostname (`scutil --get LocalHostName`) so `darwin-rebuild switch
  --flake .` picks the right host automatically, no `#attr` needed. Each
  entry sets `username`, `gitUser`, `profile`, and points at a
  `hosts/*.nix` module.
- `darwin/` — system-level config shared by every host: Nix settings,
  common Homebrew casks + MAS apps, macOS defaults (`settings.nix`),
  per-app `defaults` preferences (`apps.nix`).
- `hosts/` — per-machine modules layered on top of `darwin/`.
  `homebrew.casks`/`masApps` are list-typed, so a host file adds to the
  common list rather than replacing it. Currently `personal.nix` and
  `work.nix`.
- `home/` — home-manager: packages, shell, git, tmux, mpv, and the
  dotfiles wiring.
- `dotfiles/` — raw config files that `home/dotfiles.nix` symlinks into
  place using **out-of-store symlinks** straight into this repo. No GNU
  Stow: editing a tracked file takes effect immediately, no rebuild
  needed. Split into:
  - `dotfiles/common/` — shared across every machine (nvim, ghostty,
    starship, ccstatusline, ssh).
  - `dotfiles/<profile>/` — only symlinked on the matching host,
    selected by the `profile` value in `flake.nix` (`personal` or
    `work`). Currently just `mise/config.toml`, whose tool list differs
    per machine.

## Inputs / notable pieces

- `nixpkgs` (unstable), `nix-darwin`, `home-manager`, `nix-homebrew`.
- `meridian` — external flake I use, packaged into `home.packages`.
- Editor is stock Neovim, config vendored from an NvChad base
  (`dotfiles/common/nvim`).
- Shell is zsh + starship, completions handled by home-manager only
  (nix-darwin's zsh completion is disabled to avoid double-`compinit`).
- Terminal is Ghostty. Font is Hack Nerd Font.
- Touch ID for sudo, including inside tmux
  (`security.pam.services.sudo_local`).

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
git clone https://github.com/jeremyharland/nix-config.git ~/.config/nix-config
cd ~/.config/nix-config
```

**3a. Create `~/.ssh/config.local`**

The tracked `dotfiles/common/ssh/config` is generic. Anything
machine-specific (public IPs, personal/work-only hosts) goes in
`~/.ssh/config.local`, which stays outside the repo:

```sh
cat > ~/.ssh/config.local <<'EOF'
Host myserver
  HostName 203.0.113.5
  User someone
EOF
chmod 600 ~/.ssh/config.local
```

**4. Add or update the machine's entry in `flake.nix`**

`darwinConfigurations` must contain this Mac's `scutil --get
LocalHostName` as a key. For a new machine, add an entry pointing at a
new or existing `hosts/*.nix` file, and set:

- `hostname` — matches `scutil --get LocalHostName`
- `username` — matches the macOS account
- `gitUser` — name/email used by git (`home/git.nix`)
- `profile` — `"personal"` or `"work"`; drives which
  `dotfiles/<profile>/` variant is symlinked
- `hostModule` — path to the `hosts/*.nix` file for this machine

**5. Back up the system rc files**

```sh
mv /etc/bashrc /etc/bashrc.bak
mv /etc/zshrc /etc/zshrc.bak
```

**6. First activation**

`darwin-rebuild` doesn't exist yet on a fresh machine, so the first
switch runs through `nix run`. home-manager's `backupFileExtension =
"hm-backup"` means it moves pre-existing dotfiles aside
(`<name>.hm-backup`) instead of aborting activation.

```sh
sudo nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake ~/.config/nix-config
```

This installs Homebrew itself, all casks/MAS apps, home-manager's zsh +
starship + tmux + dotfile symlinks, and macOS defaults. Takes a while
the first time.

**7. Subsequent changes**

```sh
darwin-rebuild switch --flake ~/.config/nix-config
# or, once home-manager has run once:
rebuild
```

## Gotchas

- **Hostname-keyed, not a fixed name.** `darwinConfigurations` is keyed
  by `LocalHostName`; each entry carries its own `username`, `gitUser`,
  and `profile`. Adding a machine means adding an entry — no other file
  needs editing unless you're introducing a new profile.
- **Homebrew casks are common + per-host.** `darwin/homebrew.nix` holds
  the cask list shared by every machine; `hosts/*.nix` adds
  machine-specific casks on top (nix-darwin's `homebrew.casks` is
  list-typed, so definitions across modules concatenate rather than
  override).
- **Homebrew cleanup is aggressive.** `homebrew.onActivation.cleanup =
  "zap"` in `darwin/homebrew.nix` removes any cask/formula *not* listed
  in that file on every switch, including app data. Anything installed
  manually with `brew` will get zapped on the next `switch`.
- **Determinate-installed machines.** The classic installer (step 1)
  lets nix-darwin own `/etc/nix/nix.conf` (see `darwin/default.nix`). If
  a machine instead uses the Determinate installer, first activation
  fails with "Determinate detected, aborting activation" — fix is
  `nix.enable = false;` on that host, since Determinate's own daemon
  manages `nix.conf` instead. Not a global default: it would break
  classic-Nix machines' flakes support.
- **tmux plugins are nix-native**, not TPM. `home/tmux.nix` declares
  them via `programs.tmux.plugins` — no `prefix + I` bootstrap, no
  `~/.config/tmux/plugins` checkout.
- **nvim config is vendored as-is** (`dotfiles/common/nvim`,
  NvChad-based) — symlinked whole, not rebuilt through home-manager's
  `programs.neovim` plugin system (which would collide by trying to
  generate its own `init.lua`).
- **`~/.claude/settings.json` is deliberately untracked.** Claude Code
  rewrites it at runtime (autoMode scans, plugin toggles, theme), so
  symlinking it in would just be permanent uncommitted diff churn.
  ccstatusline's config is tracked, though — it's static once set.

## Adapting for yourself

If you want to use this as a starting point rather than a reference:

1. Fork it.
2. Edit `flake.nix`: replace hostnames, `username`, `gitUser`, and
   `profile` for your machines.
3. Rename/replace `hosts/personal.nix` and `hosts/work.nix` to whatever
   fits, and update the `hostModule` paths.
4. Rewrite the cask/MAS lists in `darwin/homebrew.nix` and `hosts/*.nix`
   — most of what's there is my apps, not defaults you'd want.
5. Drop or replace anything under `dotfiles/` you don't use, and update
   `home/dotfiles.nix` to match.
6. Remove the `meridian` input if you don't want it.

## License

MIT. Do whatever you want with it, no warranty.
