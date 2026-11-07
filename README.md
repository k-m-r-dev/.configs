# Nix macOS Configuration

Declarative macOS configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [Home Manager](https://github.com/nix-community/home-manager).

## Setup identity

Machine-specific values live in `identity.local.nix` (not hard-coded in `flake.nix`).

Flakes only include **git-tracked** files, so `identity.local.nix` must be added to git (basenames and username only — never private key material).

1. Discover values:

```bash
id -un
scutil --get LocalHostName
ls ~/.ssh
```

2. Create and track the file:

```bash
cp identity.example.nix identity.local.nix
# edit primaryUser, hostName, sshPrivateKeys
git add identity.local.nix
```

3. Field meanings:

- `primaryUser` — macOS account name (`id -un`)
- `hostName` — must match `hosts/<hostName>/` and the flake attribute (`#<hostName>`). Prefer matching `LocalHostName`.
- `sshPrivateKeys` — **basenames only** under `~/.ssh`. Tried in order; first existing file is loaded into the agent. Use `[]` to skip auto `ssh-add`.

4. Ensure `hosts/<hostName>/configuration.nix` exists (copy another host directory if needed).

If `identity.local.nix` is missing or untracked, flake evaluation fails or cannot see the file.

## Usage

Your current shell may still have an old `nix-switch` alias. Use the script once, then new shells pick up the updated alias:

```bash
unalias nix-switch 2>/dev/null
bash ~/.config/nix/scripts/nix-switch.sh
```

Later:

```bash
nix-switch
# or
sudo darwin-rebuild switch --flake ~/.config/nix#$(~/.config/nix/scripts/identity-host.sh)
```

## Structure

- `flake.nix`: Entry point and inputs (loads `identity.local.nix`).
- `identity.example.nix`: Template for a new machine.
- `identity.local.nix`: This machine’s identity (tracked; keep out of public forks if needed).
- `darwin/`: System-level configuration.
- `home/`: User-level configuration.
- `hosts/`: Host-specific configurations.
