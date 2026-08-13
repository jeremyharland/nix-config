# Migrating to a new Mac with nix-darwin

> **Read [MACHINE-NOTES.md](MACHINE-NOTES.md) first.** This README was written
> before anyone had inspected the actual machine. Several steps below are wrong
> for this setup — there are no SSH keys to copy, repos live in `~/Development`
> not `~/code`, and Phase 5's "decommission mise" should **not** be done. The
> config files have been updated to match reality; this README has not been
> rewritten, so treat it as the general plan and MACHINE-NOTES.md as the truth.

A staged migration from **Homebrew + asdf/mise/nvm** to a **full nix-darwin flake**, for a Node / Kotlin / Ruby setup.

The guiding principle: **Nix pins toolchains, native package managers resolve libraries.** Nix installs Node, the JDK, and Ruby. npm/pnpm, Gradle, and Bundler keep doing what they already do. People who try to Nixify dependency resolution for application code are the ones who give up three weeks in.

---

## Phase 0 — Inventory the old machine (do this first, it takes 10 minutes)

Run these on your **current** laptop and save the output. You cannot reconstruct this later once you've wiped it.

```bash
mkdir -p ~/migration && cd ~/migration

# What Homebrew is actually managing
brew leaves > brew-leaves.txt              # top-level formulae, not deps
brew list --cask > brew-casks.txt
brew bundle dump --file=Brewfile --force   # everything, machine-readable

# Language versions currently in use
mise ls > mise-versions.txt 2>/dev/null
asdf list > asdf-versions.txt 2>/dev/null
node --version && ruby --version && java -version

# Every version file across your repos — this tells you what to pin
find ~/code -maxdepth 3 \
  \( -name ".nvmrc" -o -name ".ruby-version" -o -name ".tool-versions" \
     -o -name ".java-version" -o -name ".mise.toml" \) \
  -not -path "*/node_modules/*" -exec sh -c 'echo "== $1"; cat "$1"' _ {} \;

# Shell config and globals
cp ~/.zshrc ~/.zprofile ~/.gitconfig . 2>/dev/null
npm ls -g --depth=0 > npm-globals.txt
gem list --local > gems.txt
```

Also note: VS Code / IntelliJ extension lists, and anything in `~/Library/Application Support` you care about.

---

## Phase 1 — Set up the new Mac

**Do not use Migration Assistant.** It will drag over `/opt/homebrew`, stale mise shims, and a `.zshrc` full of `eval` lines that will fight your new setup. Start clean and pull things across deliberately.

On the new machine:

1. Complete macOS setup, sign in, run Software Update.
2. Install Xcode Command Line Tools: `xcode-select --install` — Nix and many gems need this.
3. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
   nix-darwin manages Homebrew's *contents* declaratively, but does not install Homebrew itself.

**Carry across by hand** (these are secrets or data, not config — they don't belong in the repo):

| What | Where | How |
|---|---|---|
| SSH keys | `~/.ssh/id_*` | Copy over a trusted channel, then `chmod 600` |
| GPG keys | `gpg --export-secret-keys` | Export/import, don't copy the directory |
| Cloud credentials | `~/.aws`, `~/.config/gcloud`, `~/.kube` | Prefer re-authenticating over copying |
| Repos | `~/code` | `git clone` fresh — cleaner than rsync |
| App licences | — | 1Password / your notes |

---

## Phase 2 — Install Nix

Two installers, and this is a real fork in the road:

- **Determinate Systems installer** (`curl -fsSL https://install.determinate.systems/nix | sh -s -- install`) — clean uninstall, survives macOS upgrades better, flakes on by default. If you pick this, set `nix.enable = false;` in `darwin.nix` so nix-darwin doesn't fight Determinate over daemon management.
- **Official installer** (`sh <(curl -L https://nixos.org/nix/install)`) — leave `nix.enable = true;` and let nix-darwin manage the daemon.

I'd take Determinate for a first Nix setup, mostly because a clean uninstall path lowers the stakes considerably. Note that Determinate has been shipping its own Nix distribution rather than just an installer, and their guidance on the `nix.enable` interaction has moved around — check their current docs, since my knowledge here may be stale.

Restart your terminal, then confirm:

```bash
nix --version
nix run nixpkgs#hello
```

---

## Phase 3 — Bootstrap the flake

```bash
mkdir -p ~/nix-config && cd ~/nix-config
# copy flake.nix, darwin.nix, home.nix and templates/ in here
git init && git add -A   # flakes ignore untracked files — this step is not optional
```

**Edit before your first build:**

- `flake.nix` — `hostname`, `username`, `system` (`aarch64-darwin` for Apple Silicon)
- `darwin.nix` — `nixpkgs.hostPlatform` must match `system`; prune the `casks` list
- `home.nix` — `userName` / `userEmail` in the git block

Get your hostname with `scutil --get LocalHostName` and your username with `whoami`.

First build (before `darwin-rebuild` exists on PATH):

```bash
nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/nix-config
```

Every build after that:

```bash
sudo darwin-rebuild switch --flake ~/nix-config
# or just `rebuild`, aliased in home.nix
```

### When the first build fails

It probably will, and that's normal. The two most likely causes:

- **An option doesn't exist.** nix-darwin option names churn. `system.primaryUser`, `security.pam.services.sudo_local.touchIdAuth`, and `nix.enable` have all moved or changed form recently. If the error says an option doesn't exist, comment the line out, build, and look it up in the nix-darwin option search afterwards.
- **`system.stateVersion` mismatch.** Set it to whatever the error message tells you to.

Read the error from the bottom up — the useful line is usually the last one.

### Rolling back

This is the safety net that makes the whole thing low-risk:

```bash
darwin-rebuild --list-generations
sudo darwin-rebuild --rollback         # previous generation
sudo darwin-rebuild switch --flake ~/nix-config --rollback
```

Your previous system state is never destroyed by a rebuild. A broken config is an inconvenience, not a lost afternoon.

---

## Phase 4 — Per-project dev shells (the asdf/mise replacement)

This is the part that changes your daily habits, and the actual payoff.

For each project, using the matching file from `templates/`:

```bash
cd ~/code/some-project
cp ~/nix-config/templates/node.nix ./flake.nix   # or jvm.nix / ruby.nix
echo "use flake" > .envrc
direnv allow
```

Now `cd` into that directory and the right Node/JDK/Ruby is on your PATH. `cd` out and it's gone. No shims, no global version, no `.tool-versions` drift between your machine and CI.

Add to each project's `.gitignore`:

```
.direnv/
.bundle/
.gradle/
result
```

Commit `flake.nix`, `flake.lock`, and `.envrc` — the lock file is what makes this reproducible for teammates and CI.

**Migrate one project first.** Pick the least critical Node repo, get it working end to end, then do the rest. Don't convert twelve repos before you've validated the pattern once.

---

## Phase 5 — Decommission the old tooling

Only once every project you actively work on has a flake:

```bash
mise implode          # or: rm -rf ~/.asdf ~/.nvm
```

Then strip the corresponding `eval "$(mise activate zsh)"` / nvm sourcing lines from your shell config — though if you've set up `home.nix` properly, your `.zshrc` is now generated by home-manager and those lines are already gone.

Cross-check `brew leaves` from Phase 0 against your `home.packages`. Anything CLI-shaped should move to Nix; GUI apps stay as casks in `darwin.nix`. Once the cask list is accurate, flip `homebrew.onActivation.cleanup` to `"zap"` so Homebrew stops accumulating things you didn't declare.

---

## Suggested sequencing

Doing all of this in one sitting is how people bounce off Nix. A realistic order:

| When | What |
|---|---|
| Day 1 | Phases 0–2. Nix installed, machine usable via Homebrew as normal. |
| Day 1–2 | Phase 3. Get `darwin-rebuild switch` succeeding, even with a minimal config. |
| Week 1 | Flesh out `home.nix`. Convert one Node project. Then the rest of your Node work. |
| Week 2 | JVM projects. These are the easiest — Nix handles the JVM well. |
| Later | Ruby, as separate contained work. See the note in `templates/ruby.nix`. |

Keep the old laptop bootable and untouched until you've gone a full week without needing it.

---

## Things worth knowing up front

**IntelliJ won't see your direnv environment.** Run `echo $JAVA_HOME` inside the project shell and add that path as a Project SDK manually, or install the Direnv integration plugin. Same issue applies to any GUI app launched from Finder rather than a shell.

**Ruby is the hard part.** Native gem extensions expect an FHS layout that Nix doesn't provide. See the note at the bottom of `templates/ruby.nix` — keeping Ruby on mise is a defensible permanent choice, not a failure.

**`nix flake update` updates everything at once.** Run it deliberately, commit the `flake.lock` change on its own, and rebuild. If something breaks you have a one-line revert.

**Disk usage grows.** Every generation is retained until garbage-collected. The `nix.gc` block in `darwin.nix` handles this weekly; `nix store gc` runs it on demand.

**Docker still wants Docker Desktop** (or OrbStack / colima) on macOS. Nix doesn't change that — it's a cask.

---

## A caveat on this config

I wrote these files without being able to evaluate them — I have no network access here, so nothing has been checked against a real nixpkgs. Treat them as a well-informed starting point rather than tested code. Expect to fix two or three option names on the first build. That's the normal experience, not a sign anything is wrong.
