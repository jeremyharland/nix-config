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

**`pkgs.watch` may not exist** under that attribute name (it's part of
`procps`). It was inherited from the original config and has not been
evaluated. If the first build complains, drop the line.

**63 VS Code extensions** are recorded in `inventory/Brewfile` as `vscode`
entries. `brew bundle install --file=inventory/Brewfile` on the new machine
will restore them, or use VS Code Settings Sync.

---

## Still to do

- [ ] Install Nix (Determinate) and get `darwin-rebuild switch` green
- [ ] Copy `~/.ssh/config` and `~/.secrets` to the new machine by hand
- [ ] Set the new machine's `LocalHostName` to `jeremy-macbook`, or rename the
      flake entry
- [ ] Migrate `tools/chartdb` (has a `.nvmrc`) as the first flake conversion
- [ ] Once the cask list is verified, flip `homebrew.onActivation.cleanup` to `"zap"`
