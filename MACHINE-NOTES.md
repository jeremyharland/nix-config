# Machine notes — findings from the old MacBook

`README.md` was written before anyone had looked at the actual machine. This
file records where reality differs, and what was changed as a result. Read it
before following the README literally.

Source machine: `Jeremys-MacBook-Pro-2`, macOS 15.7.3, arm64, user `jeremyharland`.
Inventory captured 2026-08-13 into `inventory/`.

---

## Corrections to the README

**Phase 2's Determinate advice is out of date.** Install with the graphical
`Determinate.pkg` (recommended for nix-darwin users) or:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --determinate
```

Note the `--determinate` flag — without it you get upstream Nix via their
installer, not Determinate Nix. Then see the `determinateNix.enable` note
below; **do not** set `nix.enable = false` as the README instructs.

**There are no SSH keys to copy.** `~/.ssh/` contains only `config` and
`known_hosts` — no `id_*` files. Authentication and commit signing both go
through the **1Password SSH agent** (`IdentityAgent` in `~/.ssh/config`,
`op-ssh-sign` in `~/.gitconfig`). The README's "copy `~/.ssh/id_*` over a
trusted channel" step does not apply. On the new Mac: install 1Password, sign
in, enable the SSH agent, done. The `user.signingkey` in `home.nix` is a
public key and is safe to commit.

**Repos live in `~/Development`, not `~/code`.** Five repos. Only two carry
version files: `fnox/mise.toml` and `tools/chartdb/.nvmrc` (`v24`). Adjust the
Phase 0 `find` command accordingly.

**Phase 5 "decommission mise" is wrong for this machine — do not do it.**
See below.

---

## mise is staying

The README frames mise as a thing Nix replaces. That holds for *language
runtimes* only. On this machine mise also manages a large set of tools, many
with no nixpkgs equivalent:

`fnox` · `pitchfork` · `hk` · `usage` · `aube` · `pkl` · `vault` · `age` ·
`git-cliff` · `actionlint` · `bitwarden` · `1password` · `cargo-binstall` ·
`cargo-edit` · `cargo-msrv` · `micronaut` · `copier`

Several of these are jdx tools, and `fnox` is your own project in
`~/Development/fnox` (whose `mise.toml` drives its whole build). Ripping mise
out would break that repo's task runner.

So: `mise` is in `home.packages`, and `mise activate zsh` stays in the shell
init. The split is —

| Concern | Owner |
|---|---|
| Node / JDK / Ruby / Go / Rust per project | per-project Nix flake (`templates/`) |
| Everything else mise installs | mise |
| Global CLI tools | Nix (`home.packages`) |
| GUI apps, native build deps, DB servers | Homebrew (`darwin.nix`) |

**asdf, however, is genuinely dead.** It holds only stale duplicates
(nodejs 16/18/20/22, pnpm 8/9, ruby 3.3.3) that mise already covers.
`rm -rf ~/.asdf` and drop the `asdf` brew is safe.

Also note there are **9 Node versions and 8 pnpm versions** installed under
mise. Don't recreate that on the new machine — install what projects actually
pin and let the rest go.

---

## Toolchains the templates don't cover

`templates/` has `node.nix`, `jvm.nix`, `ruby.nix`. Also in active use:
**Go 1.26**, **Rust 1.90**, **Python 3.12**, **Terraform 1.15**, **Kotlin
2.3.21**, **Gradle 9.5.1**. Add templates as you migrate projects that need
them, or leave those on mise — the hybrid is fine.

Current global runtimes, for reference: Node 20.13.1, Ruby 3.3.3,
OpenJDK 25.0.3 (temurin-25 via mise).

---

## Config changes made

- **`flake.nix`** — filled in `username`/`system`; replaced the single
  `hostname` with a `mkHost` helper and two `darwinConfigurations` entries so
  the same repo builds on both laptops without editing.
- **`flake.nix` / `darwin.nix`** — Determinate integration, done the current
  way rather than the way the README describes. The README says to set
  `nix.enable = false`; that advice is now superseded. Determinate ships its
  own nix-darwin module, so the flake takes a `determinate` input
  (`https://flakehub.com/f/DeterminateSystems/determinate/3`), adds
  `determinate.darwinModules.default` to the module list, and `darwin.nix` sets
  `determinateNix.enable = true`. That option disables nix-darwin's built-in
  Nix management by itself — **do not also set `nix.enable = false`**. The
  `nix.settings`/`nix.gc`/`nix.optimise` block is commented out since
  Determinate owns `nix.conf`.
  Ref: <https://docs.determinate.systems/guides/nix-darwin/>
- **`darwin.nix`** — replaced the guessed cask list with the 26 casks actually
  installed, added the three required taps (`homebrew/services`,
  `minio/stable`, `nikitabobko/tap`), and split `brew leaves` into a kept-in-brew
  list. Notably: no Raycast, no Docker Desktop (**OrbStack** + colima), no
  jetbrains-toolbox (IntelliJ direct), Chromium/Firefox rather than Chrome.
- **`home.nix`** — real git identity plus the 1Password signing config;
  oh-my-zsh (`git` plugin, no theme, starship owns the prompt); the full
  `initContent` carried over from the old `.zshrc`; `mise` added; `programs.ssh`
  disabled with an explanation.
- **`templates/`** — the three template files moved into this directory, which
  is where the README already said they were.

---

## Gotchas for the first build

**home-manager refuses to clobber existing dotfiles.** The first `switch` will
fail if `~/.zshrc` exists. Back up and remove first:

```bash
mv ~/.zshrc ~/.zshrc.pre-nix
mv ~/.gitconfig ~/.gitconfig.pre-nix
```

`~/.gitconfig` matters for a subtler reason: home-manager writes
`~/.config/git/config`, but `~/.gitconfig` takes **precedence** over it. Leave
it in place and your Nix git config is silently ignored.

**`~/.oh-my-zsh` is a git checkout.** home-manager's `oh-my-zsh` module uses
the nixpkgs copy instead. Once the build works, `rm -rf ~/.oh-my-zsh`.

**"Unexpected files in /etc, aborting activation."** The first `switch` stops
on `/etc/nix/nix.custom.conf` and `/etc/pam.d/sudo_local`. Both are safe to
rename — checked before doing so:

- `nix.custom.conf` was written by the Determinate installer and contained only
  comments. nix-darwin takes it over via `determinateNix.customSettings`.
- `sudo_local` was hand-created 16 Jul 2024 (pre-dates all of this) and holds
  exactly `auth sufficient pam_tid.so` — the same line
  `security.pam.services.sudo_local.touchIdAuth = true` generates, so Touch ID
  for sudo survives.

```bash
sudo mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin
sudo mv /etc/pam.d/sudo_local /etc/pam.d/sudo_local.before-nix-darwin
```

**Custom Nix settings go in `determinateNix.customSettings`**, not
`nix.settings` and not by hand-editing `/etc/nix/nix.custom.conf` (which is
regenerated). The module force-disables `nix.enable` itself. These keys are
rejected by design, being Determinate-owned: `bash-prompt-prefix`,
`external-builders`, `extra-nix-path`, `netrc-file`, `ssl-cert-file`,
`upgrade-nix-store-path-url`.

**`pkgs.watch` may not exist** under that attribute name (it's part of
`procps`). It was inherited from the original config and has not been
evaluated. If the first build complains, drop the line.

**63 VS Code extensions** are recorded in `inventory/Brewfile` as `vscode`
entries. `brew bundle install --file=inventory/Brewfile` on the new machine
will restore them, or use VS Code Settings Sync.

---

## What Homebrew is still for

Very little, after pruning — `brews` is down to four:

1. **GUI apps** — all 26 casks. nixpkgs' macOS app coverage is patchy and often
   just repackages the same DMG with worse update handling. This is permanent,
   and is the main reason Homebrew stays at all.
2. **`cocoapods` / `fastlane` / `watchman`** — need a system Ruby and Xcode's
   directory layout, which Nix doesn't provide.
3. **`redis`** — as a launchd daemon via `brew services`.

Postgres is deliberately **not** here. `psql` and `pg_config` come from
`pkgs.postgresql` in a per-project dev shell (`templates/ruby.nix` already
declares it), or run the server in a container via OrbStack. This is the
guiding principle applied honestly: if it's a project dependency, it belongs to
the project, not the machine.

Everything else that was in `brew leaves` is gone from the config: JDKs go to
mise or project flakes, native build deps go to per-project dev shells, and the
CLI tools moved to `home.packages`. The removed formulae are listed in a comment
in `darwin.nix` and the full original set is in `inventory/brew-leaves.txt`.

**nix-darwin does not install Homebrew.** Install it by hand on the new machine
first, or the `homebrew` block silently does nothing.

`cleanup` stays at `"none"` so Homebrew never removes anything undeclared. On
the old machine that means the pruned formulae remain installed but unmanaged —
harmless. On the new machine they simply never get installed.

---

## GUI app config the first inventory missed

Phase 0 captured shell config and `~/.config`, and stopped there. That missed
app configuration living in macOS-specific locations. Found afterwards, when
the new machine's terminal came up unthemed:

| What | Where | Status |
|---|---|---|
| Ghostty theme | `~/Library/Application Support/com.mitchellh.ghostty/config` | now in `home.nix` |
| kitty | `~/.config/kitty/kitty.conf` | now in `home.nix` |
| iTerm2 | `~/Library/Preferences/com.googlecode.iterm2.plist` | **copy by hand** — binary plist |
| nvim | `~/.config/nvim` — an NvChad checkout | **clone separately** |
| Hack Nerd Font | `font-hack-nerd-font` cask | already declared |

Ghostty's theme is `light:Catppuccin Latte,dark:Catppuccin Mocha` with
`window-theme = auto`, i.e. it follows the macOS light/dark setting.

Note that `programs.ghostty` and `programs.kitty` are deliberately **not** used:
both install their own copy of the terminal from nixpkgs, which would duplicate
the cask. The config files are written directly instead — and for Ghostty via
`home.file` rather than `xdg.configFile`, because on macOS it reads from
Application Support.

**The prompt was never lost.** The old `.zshrc` set
`ZSH_THEME="robbyrussell"` at line 11 but then ran `starship init zsh` at line
123, *after* sourcing oh-my-zsh — so starship always won and robbyrussell never
rendered. There is no `~/.config/starship.toml`, so it was stock starship. The
Nix config reproduces that exactly, which is why `oh-my-zsh.theme = ""` changes
nothing visible. To actually use robbyrussell you would have to set
`programs.starship.enable = false` and `oh-my-zsh.theme = "robbyrussell"`.

If anything else looks wrong on the new machine, check macOS-specific paths
before assuming the Nix config is at fault: `~/Library/Application Support/`,
`~/Library/Preferences/`.

---

## New machine runbook

Ordered, and each step assumes the one before it worked.

1. **macOS setup.** Sign in, run Software Update. Do **not** use Migration
   Assistant — it drags `/opt/homebrew` and stale shims across.
2. `xcode-select --install`
3. **Name the machine** so `darwin-rebuild` can find its config:
   `sudo scutil --set LocalHostName jeremy-macbook`
   (or rename the `jeremy-macbook` key in `flake.nix` to whatever you pick)
4. **Install Homebrew** — nix-darwin manages its contents, not its existence:
   `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
5. **Install 1Password**, sign in, and enable the SSH agent in
   Settings → Developer. This is what gets you git auth *and* commit signing;
   there are no key files to copy.
6. **Install Determinate Nix:**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
     sh -s -- install --determinate
   ```
   Restart the terminal, then check `nix --version`.
7. **Clone this repo** to `~/nix-config`. The path matters — the `rebuild`
   alias hardcodes it.
8. **First switch.** `darwin-rebuild` isn't on PATH yet, so:
   ```bash
   nix run nix-darwin#darwin-rebuild -- build --flake ~/nix-config
   sudo ~/nix-config/result/sw/bin/darwin-rebuild switch --flake ~/nix-config
   ```
   Expect the `/etc` guard to fire on `nix.custom.conf` and possibly
   `sudo_local` — see the gotchas above. After this, `rebuild` works.
9. **Copy by hand** (secrets and data, not config — they are not in this repo):
   - `~/.secrets` — sourced by the generated `.zshrc`
   - `~/.ssh/config` — deliberately unmanaged, see the note in `home.nix`
   - `~/.config/mise/config.toml` — a snapshot is in `inventory/`
10. **Re-auth** rather than copy: `aws`, `gcloud`, `kubectl`, `gh auth login`.
11. **Install mise**, then only the tool versions you actually need. Do not
    recreate the old machine's 9 Node and 8 pnpm versions.
12. **Clone repos** into `~/Development` fresh, rather than rsyncing.
13. **VS Code extensions:** `brew bundle install --file=inventory/Brewfile`
    restores all 63, or use Settings Sync.

### Then, deliberately and not on day one

- [ ] Convert `tools/chartdb` (has a `.nvmrc`) as the first project flake —
      validate the pattern on one repo before doing the rest
- [ ] Add templates for Go / Rust / Python / Terraform as needed
- [ ] Once the cask list is verified against real use, flip
      `homebrew.onActivation.cleanup` to `"zap"`
- [ ] Consider re-enabling `homebrew.onActivation.upgrade` once this is the
      only machine in use
- [ ] Postgres is no longer installed machine-wide. Before retiring the old
      laptop, `pg_dump` anything you still want out of its `@14`/`@16` data
      directories — a fresh machine will have no way to read them.
- [ ] `rm -rf ~/.asdf` on the old machine; asdf holds only stale duplicates
- [ ] Delete the `~/*.pre-nix`, `~/*.hm-backup` and `~/.zshrc.stub-backup`
      files once you've lived in the new shell for a few days
- [ ] `~/.zlogin` still sources RVM. home-manager doesn't manage that file, so
      it survives untouched — but it's dead weight given Ruby comes from mise.
      Don't copy it to the new machine.
