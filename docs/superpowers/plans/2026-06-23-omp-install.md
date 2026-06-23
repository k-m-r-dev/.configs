# OMP Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install `omp` via Bun during Home Manager activation, keep it easy to update on rebuild, and enable guarded zsh completions.

**Architecture:** Extend the existing activation hook in `home/packages.nix` with a Bun-specific helper that installs and updates `@oh-my-pi/pi-coding-agent` independently of `fnm`. Add a guarded `omp` completion stanza to `home/shell.nix` so completion activates only when the binary is present.

**Tech Stack:** Nix, Home Manager activation hooks, zsh, Bun

---

### Task 1: Add Bun-managed OMP installation

**Files:**
- Modify: `home/packages.nix`
- Test: `darwin-rebuild switch --flake ~/.config/nix --dry-run`

- [ ] **Step 1: Add Bun discovery and helper logic to the activation hook**

Add Bun binary discovery near the existing npm discovery and define a Bun helper that ensures a global package is installed and updated:

```sh
bun_bin="$(command -v bun || true)"
if [ -z "$bun_bin" ] && [ -x "$HOME/.nix-profile/bin/bun" ]; then
  bun_bin="$HOME/.nix-profile/bin/bun"
fi
if [ -z "$bun_bin" ] && [ -x "/etc/profiles/per-user/$USER/bin/bun" ]; then
  bun_bin="/etc/profiles/per-user/$USER/bin/bun"
fi

bun_ensure_latest() {
  local pkg="$1"
  local installed latest
  installed="$( "$bun_bin" pm ls -g 2>/dev/null | grep -F "$pkg@" | sed 's/.*@//' | head -n 1 )"
  latest="$( "$npm_bin" view "$pkg" version 2>/dev/null || true )"

  if [ -z "$latest" ]; then
    echo "Could not fetch $pkg latest version; skipping"
  elif [ -z "$installed" ]; then
    echo "Installing $pkg@$latest via bun..."
    "$bun_bin" install -g "$pkg@latest"
  elif [ "$installed" != "$latest" ]; then
    echo "Updating $pkg ($installed -> $latest) via bun..."
    "$bun_bin" remove -g "$pkg" >/dev/null 2>&1 || true
    "$bun_bin" install -g "$pkg@latest"
  fi
}
```

- [ ] **Step 2: Run a dry Nix evaluation to verify the activation string still parses**

Run: `sudo darwin-rebuild switch --flake ~/.config/nix --dry-run`
Expected: evaluation succeeds with no syntax errors in `home/packages.nix`

- [ ] **Step 3: Register the OMP package in the activation hook**

Add the Bun-managed package install call after the existing npm-managed packages:

```sh
if [ -z "$bun_bin" ]; then
  echo "bun not found in activation; skipping bun global installs"
else
  bun_ensure_latest @oh-my-pi/pi-coding-agent
fi
```

- [ ] **Step 4: Re-run the dry Nix evaluation**

Run: `sudo darwin-rebuild switch --flake ~/.config/nix --dry-run`
Expected: evaluation succeeds with the new Bun-managed activation logic present

### Task 2: Add guarded zsh completions

**Files:**
- Modify: `home/shell.nix`
- Test: `sudo darwin-rebuild switch --flake ~/.config/nix --dry-run`

- [ ] **Step 1: Add a guarded completion block to zsh init content**

Add this shell snippet near the PATH/tool initialization in `programs.zsh.initContent`:

```sh
if command -v omp >/dev/null 2>&1; then
  eval "$(omp completions zsh)"
fi
```

- [ ] **Step 2: Run a dry Nix evaluation to verify shell config syntax**

Run: `sudo darwin-rebuild switch --flake ~/.config/nix --dry-run`
Expected: evaluation succeeds with no syntax errors in `home/shell.nix`

### Task 3: Validate the installed workflow

**Files:**
- Modify: none
- Test: live shell commands after rebuild

- [ ] **Step 1: Apply the configuration**

Run: `sudo darwin-rebuild switch --flake ~/.config/nix`
Expected: activation completes and installs or updates `@oh-my-pi/pi-coding-agent`

- [ ] **Step 2: Verify OMP is on PATH**

Run: `command -v omp && omp --version`
Expected: prints the `omp` binary path followed by a version string

- [ ] **Step 3: Verify completions command works**

Run: `omp completions zsh >/dev/null`
Expected: exits successfully with status 0

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-06-23-omp-install.md home/packages.nix home/shell.nix
git commit -m "feat: manage omp via bun activation"
```