# OMP Install Design

## Goal

Install `oh-my-pi` (`omp`) on this macOS system using the upstream-recommended approach while keeping the setup easy to update and stable across `fnm`-managed Node version changes.

## Context

- This repository manages system and user tooling declaratively with nix-darwin and Home Manager.
- User-level CLI tools already follow two patterns:
  - Nix-managed packages in `home/packages.nix`
  - Activation-managed globally installed CLIs in the `activation.npmGlobals` hook in `home/packages.nix`
- `bun` is already installed in `home.packages`.
- The user primarily uses `fnm` for project Node versions, so system-level tooling should avoid being coupled to whichever Node version is currently active.
- `zsh` is managed in `home/shell.nix` and already contains custom shell initialization.

## Requirements

- Use the recommended upstream install approach for `omp`.
- Make updates easy and repeatable.
- Avoid coupling `omp` to `fnm` global npm state.
- Integrate cleanly with the existing Home Manager structure.
- Enable `zsh` completions for `omp`.

## Chosen Approach

Manage `omp` through the existing Home Manager activation hook, but install it with Bun instead of npm.

Upstream recommends:

```sh
bun install -g @oh-my-pi/pi-coding-agent
```

That recommendation aligns with this repo better than npm or Homebrew because:

- Bun is already present as a system-level tool in this configuration.
- Bun global installs are independent of `fnm`'s active Node version.
- The existing activation hook already handles "global CLI, keep it up to date" behavior for other tools.
- Rebuild-driven installation keeps the tool lifecycle declarative enough for this setup without introducing a custom Nix derivation.

## Alternatives Considered

### 1. Homebrew tap install

Install with:

```sh
brew install can1357/tap/omp
```

Rejected because it would split lifecycle management across Brew and Home Manager, while the rest of this repo already manages comparable CLI tools elsewhere.

### 2. npm global install

Install with:

```sh
npm install -g @oh-my-pi/pi-coding-agent
```

Rejected because npm global installs are commonly tied to the active Node version, which is undesirable on a machine where `fnm` is used heavily across projects.

### 3. Custom Nix package or overlay

Rejected because it adds maintenance cost that is not justified here. The user wants a setup that is easy to update, and upstream already documents a Bun-first install flow.

## Implementation Plan

### 1. Extend activation-managed CLI installation

Update `home/packages.nix` so the activation hook can ensure `@oh-my-pi/pi-coding-agent` is installed and updated with Bun.

Planned behavior:

- Discover the `bun` binary during activation.
- Reuse the existing "ensure latest" pattern, but add a Bun-specific helper for Bun-managed globals.
- Install `@oh-my-pi/pi-coding-agent` when missing.
- Update it on future rebuilds when the upstream registry version changes.

The change should stay narrow in scope:

- Keep existing npm-managed tools working as they do today.
- Add Bun-based management only for `omp`.

### 2. Add guarded zsh completion initialization

Update `home/shell.nix` to enable `omp` completions in interactive shells.

Planned behavior:

- Only initialize completion if `omp` is present on `PATH`.
- Use the binary-generated completion output so completions stay aligned with the installed version.

Expected shell snippet shape:

```sh
if command -v omp >/dev/null 2>&1; then
  eval "$(omp completions zsh)"
fi
```

This avoids startup errors on shells opened before the first successful rebuild or during partial transitions.

## Verification

After implementation:

1. Run a narrow Nix validation for the touched configuration.
2. Apply the config with the normal rebuild flow.
3. Confirm `omp --version` works in a fresh shell.
4. Confirm `omp completions zsh` succeeds.
5. Confirm tab completion initializes without shell startup errors.

## Tradeoffs

- This is not a pure Nix package installation.
- It relies on the activation hook to manage an external package registry.
- In return, it follows upstream guidance, avoids `fnm` coupling, and keeps updates simple through the rebuild path the user already uses.

## Scope Boundaries

This change does not:

- Replace the existing npm-based activation pattern for other tools.
- Convert `omp` into a custom Nix derivation.
- Change how `fnm` is used for project-local Node workflows.