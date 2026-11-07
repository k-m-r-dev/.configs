# Nix macOS Configuration

Declarative macOS configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager).

## Hosts and identity

Each machine is a pure flake attribute. Per-host `primaryUser` and `sshPrivateKeys` live under `hosts/<name>/identity.nix` (committed; SSH **basenames** only, never key material).

1. Discover this Mac’s name: `scutil --get LocalHostName`
2. Ensure `hosts/<name>/configuration.nix` and `hosts/<name>/identity.nix` exist and that `<name>` is listed in `flake.nix` (`hostNames`).
3. Switch with `#$(scutil --get LocalHostName)` so the attr matches LocalHostName.

`identity.local.nix` is gitignored leftover from an earlier experiment — do not use it.

## Usage

```bash
unalias nix-switch 2>/dev/null
bash ~/.config/nix/scripts/nix-switch.sh
```

Later (after Home Manager updates the alias):

```bash
nix-switch
# or
sudo darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)
```

## Structure

- `flake.nix`: Inputs and `darwinConfigurations` for each host.
- `hosts/<name>/identity.nix`: `primaryUser` + `sshPrivateKeys` for that host.
- `hosts/<name>/configuration.nix`: Host-specific darwin/HM tweaks.
- `darwin/`: Shared system-level configuration.
- `home/`: Shared user-level configuration.
