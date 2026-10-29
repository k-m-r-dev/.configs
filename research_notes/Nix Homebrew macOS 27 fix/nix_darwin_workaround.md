# Nix-side fix for Homebrew `unknown or unsupported macOS version: :dunno` during a nix-darwin switch

A nix-darwin switch can get past this error by updating the pinned Homebrew to a release that knows macOS 27 (Golden Gate), or by turning off the Homebrew Bundle activation step. The locked Homebrew 5.1.11 has no macOS 27 name, and nix-darwin has no documented option that makes that old Homebrew accept the version.

Terms used below: Nix is the package manager. nix-darwin is the macOS system configuration tool that `darwin-rebuild switch` applies. Homebrew is the separate macOS package manager invoked as `brew`. nix-homebrew is the nix-darwin module that installs and pins that Homebrew. A Brewfile is the package list Homebrew Bundle installs. The local lock is context from this repo and was not changed.

## Where does nix-darwin print `Homebrew bundle...`, which brew command does it run, and can `HOMEBREW_MACOS_VERSION` be injected through a documented option?

### Takeaway

At nix-darwin revision `56c666e108467d87d13508936aade6d567f2a501`, the text `Homebrew bundle...` is printed by `system.activationScripts.homebrew.text`, which then runs `brew bundle` on the generated Brewfile. `homebrew.onActivation.extraEnv` is the documented way to add environment variables to that command. It does not document `HOMEBREW_MACOS_VERSION`, and Homebrew’s own startup script replaces that variable with the output of `sw_vers` before version checks run.

### Cited Findings

- The activation script is installed only when `homebrew.enable` is true. It prints `Homebrew bundle...` to standard error, and if `${prefix}/bin/brew` exists it runs `sudo --preserve-env=PATH --user=<user> --set-home env` plus `homebrew.onActivation.brewBundleCmd`. If `brew` is missing it prints `error: Homebrew is not installed, skipping...` and does not fail the script. — [nix-darwin `modules/homebrew.nix` at `56c666e`](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix)
- `brewBundleCmd` is an internal read-only string. With the user’s settings (`autoUpdate = false`, `upgrade = false`, `cleanup = "uninstall"`) it expands to `HOMEBREW_NO_AUTO_UPDATE=1`, then each `extraEnv` entry as `KEY=VALUE`, then `brew bundle --file='<store Brewfile>' --no-upgrade --cleanup`, then any `extraFlags`. — [same file](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix); local settings in [darwin/homebrew.nix](file:///Users/khandkermahmudur/.config/nix/darwin/homebrew.nix)
- `homebrew.onActivation.extraEnv` is documented as “Extra environment variables to set when nix-darwin invokes `brew bundle [install]` during system activation.” The manual example is `HOMEBREW_NO_ENV_HINTS` and `HOMEBREW_NO_ANALYTICS`. The text says it is useful for Homebrew’s `HOMEBREW_NO_*` variables because activation runs under `sudo` and does not inherit the user shell. — [same file](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix)
- `homebrew.enable`’s description says the module generates a Brewfile and passes it to `brew bundle` during system activation. Enabling the module does not install Homebrew. — [nix-darwin manual, `homebrew.enable`](https://nix-darwin.github.io/nix-darwin/manual/)
- This repo’s lock pins `brew-src` to Homebrew tag `5.1.11`, revision `6f293daa9f9f5832e13b497976335e90509886d7`, through nix-homebrew revision `b3a87b4793205cc111f3c61e25e018ffac3b8039`. nix-darwin is `56c666e108467d87d13508936aade6d567f2a501`. nixpkgs is `nixpkgs-unstable` revision `a0991c886dc83e6e9de01d5266e4842985b1850e`. — [flake.lock](file:///Users/khandkermahmudur/.config/nix/flake.lock)
- Homebrew 5.1.11’s version map stops at `tahoe: "26"`. `MacOSVersion#to_sym` returns the symbol `:dunno` when the major version is not in that map. `MacOSVersion.from_symbol` raises `MacOSVersion::Error` for an unknown symbol, and that error’s message is `unknown or unsupported macOS version: #{version.inspect}`. For the symbol `:dunno`, Ruby’s `inspect` is the text `:dunno`. A numeric version such as `27.0` matches the constructor’s version pattern, so the constructor itself does not produce this message for a normal macOS 27 product version. — [Homebrew `macos_version.rb` at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/macos_version.rb)
- Homebrew 5.1.14 `Library/Homebrew/brew.sh` sets `HOMEBREW_MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"` whenever it is running on macOS. The assignment does not keep a value that was already in the environment. Current Homebrew `main` does the same assignment. — [brew.sh at 5.1.14](https://github.com/Homebrew/brew/blob/5.1.14/Library/Homebrew/brew.sh); [brew.sh on main](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/brew.sh)
- Homebrew’s public install documentation lists macOS requirements. It does not list `HOMEBREW_MACOS_VERSION` as a user setting. The Ruby class that reads the version is marked as a private interface. — [Homebrew installation docs](https://docs.brew.sh/Installation); [MacOSVersion Ruby API](https://docs.brew.sh/rubydoc/MacOSVersion.html)
- Current Homebrew `main` includes `golden_gate: "27"` in that version map, and its `brew.sh` still contains `HOMEBREW_MACOS_NEWEST_SUPPORTED="26"` and `HOMEBREW_MACOS_NEWEST_UNSUPPORTED="27"`. — [MacOSVersion Ruby API](https://docs.brew.sh/rubydoc/MacOSVersion.html); [brew.sh on main](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/brew.sh)

### Inferences

- `homebrew.onActivation.extraEnv.HOMEBREW_MACOS_VERSION` would put the variable in the `brew bundle` process environment, because the activation script prefixes `KEY=VALUE` after `sudo` and before `brew`. Homebrew 5.1.14 and current `main` then overwrite it from `sw_vers`, so the documented option cannot rename macOS 27 to an older release for those builds.
- The exact `:dunno` string matches `MacOSVersion::Error` receiving the symbol `:dunno`. The locked 5.1.11 map has no entry for major version 27, and `to_sym` is what manufactures that symbol. The line inside `brew bundle` that raises was not isolated.

### Gaps

- `brew.sh` was read at tag 5.1.14 and on current `main`, not at the locked tag 5.1.11. The overwrite behavior on 5.1.11 itself was not byte-checked.
- No Homebrew man page entry was found that tells users to set `HOMEBREW_MACOS_VERSION`. Absence from the pages that were fetched is not a proof that no document mentions it.

## Which `homebrew.*` options disable brew bundle while keeping the rest of the switch, and what breaks if bundle is skipped while nix-homebrew stays enabled?

### Takeaway

`homebrew.enable = false` is the documented switch that removes the bundle activation script. The `onActivation` submodule has no skip flag. Leaving nix-homebrew enabled keeps the pinned Homebrew installation in place and stops nix-darwin from installing, upgrading, or cleaning the declared formulae and casks on later switches.

### Cited Findings

- `system.activationScripts.homebrew.text` is wrapped in `mkIf cfg.enable`. Shell integration for bash, zsh, and fish, and `environment.variables` from `homebrew.global`, use the same condition. — [nix-darwin `modules/homebrew.nix` at `56c666e`](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix)
- Documented `homebrew.onActivation` options in that revision are `cleanup`, `autoUpdate`, `upgrade`, `extraEnv`, and `extraFlags`. `brewBundleCmd` is internal. None of those options omit the `brew bundle` invocation. `extraFlags` appends arguments to it. — [same file](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix)
- The manual default for `homebrew.enable` is `false`. The description says the module’s job is Homebrew Bundle management during activation, and that Homebrew itself is installed separately. — [nix-darwin manual, `homebrew.enable`](https://nix-darwin.github.io/nix-darwin/manual/)
- `cleanup = "uninstall"` is defined as invoking `brew bundle` with the cleanup flag so Homebrew uninstalls packages that are not in the generated Brewfile. `cleanup = "zap"` also zaps cask files. The default is `"none"`, which leaves extra packages installed. The user’s file sets `"uninstall"`. — [same module](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix); [darwin/homebrew.nix](file:///Users/khandkermahmudur/.config/nix/darwin/homebrew.nix)
- The bundle activation script does not capture `brew`’s exit code. The separate `cleanup = "check"` path does capture it and exits 2 on failure. A failing `brew bundle` therefore fails the bundle activation script. — [same module](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix)
- nix-homebrew “only installs Homebrew itself and does not manage any package installed by it.” Declarative formulae and casks are the nix-darwin `homebrew.*` options, which “work well in tandem with nix-homebrew.” — [nix-homebrew README](https://github.com/zhaofengli/nix-homebrew)
- This config sets `nix-homebrew.enable = true` and `autoMigrate = true`, and it puts `/opt/homebrew/bin` on `environment.systemPath` outside the Homebrew module. — [darwin/default.nix](file:///Users/khandkermahmudur/.config/nix/darwin/default.nix)

### Inferences

- Setting `homebrew.enable = false` while leaving `nix-homebrew.enable = true` removes the failing activation script and leaves the nix-homebrew-managed Homebrew prefix. Switches no longer install the declared brews, casks, or taps, and they no longer run `cleanup = "uninstall"`. Packages already installed by Homebrew stay installed, because nothing in the remaining activation removes them.
- Emptying `brews`, `casks`, and `taps` while `homebrew.enable` stays true still runs `brew bundle`. With this file’s `cleanup = "uninstall"`, that command is documented to uninstall Homebrew packages missing from the Brewfile. That is a destructive cleanup, not a skip.
- Forcing `system.activationScripts.homebrew.text` to an empty string with Nix’s `mkForce` would drop only that script and could leave `homebrew.enable` true. That is ordinary Nix module overriding. It is not a `homebrew.*` option, and it was not tested.

### Gaps

- nix-homebrew’s `autoMigrate` definition was not re-read, so the notes do not claim what a later switch does to an already migrated prefix when the bundle step is absent.
- The nix-darwin activation runner’s exact “stop the rest of the scripts” behavior was not read. The user’s log already shows the switch exiting at this error after Applications, pam, `/etc`, launchd, and networking.

## Do nix-darwin, Nixpkgs, or Determinate Systems issues document macOS 27 or this Homebrew error, and do they recommend a fix?

### Takeaway

The matching report is nix-homebrew issue 152, closed by moving the pinned Homebrew to 6.0.1. Homebrew 6.0.0 is the release that added initial macOS 27 support. No nix-darwin issue and no Determinate Systems document found in this search tracks this exact `:dunno` error. Updating only the Homebrew pin, on this older nix-darwin, can trade the version error for Homebrew 6’s cleanup-flag and tap-trust changes.

### Cited Findings

- nix-homebrew issue 152, opened 2026-06-12 and closed 2026-06-13, reports `unknown or unsupported macOS version: :dunno` on macOS 27. `brew update-reset` prints `No remote 'origin' in /opt/homebrew/Library/.homebrew-is-managed-by-nix, skipping update and reset!` A comment recommends overriding `nix-homebrew.inputs.brew-src.url` to `github:Homebrew/brew/6.0.1`. The maintainer closed it as fixed by pull request 154, which upgrades Homebrew from 5.1.14 to 6.0.1. — [nix-homebrew issue 152](https://github.com/zhaofengli/nix-homebrew/issues/152)
- Homebrew pull request 22592, merged 2026-06-09, is “Preliminary macOS 27 (Golden Gate) support.” It adds the `golden_gate` version symbol. Issue 152 points at that pull request and at the Homebrew 6.0.0 announcement. — [Homebrew pull request 22592](https://github.com/Homebrew/brew/pull/22592)
- The Homebrew 6.0.0 announcement on 2026-06-11 says the release includes “initial support for macOS 27 (Golden Gate)” and a new tap trust mechanism. — [Homebrew 6.0.0](https://brew.sh/2026/06/11/homebrew-6.0.0/)
- Homebrew’s support-tier document, as fetched from `main`, lists macOS Golden Gate 27 as Tier 1 for Apple Silicon as of September 2026, and lists “Homebrew installations managed by Nix (e.g. nix-darwin or nix-homebrew)” as Tier 3. Tier 3 means Homebrew does not commit to fixing those setups. — [Homebrew Support Tiers](https://github.com/Homebrew/brew/blob/main/docs/Support-Tiers.md)
- Older Homebrew issues with the same `:dunno` text (macOS 15 in 2024) were closed because the installed Homebrew was too old for that release. Maintainers told reporters to update Homebrew. One reporter’s `HOMEBREW_VERSION` was 4.2.14. — [Homebrew issue 18222](https://github.com/Homebrew/brew/issues/18222); [Homebrew issue 18385](https://github.com/Homebrew/brew/issues/18385)
- nix-darwin pull request 1789, merged 2026-06-17, closes issue 1787 (`homebrew.onActivation.cleanup` broke because `brew bundle --cleanup` changed). The author writes that the cleanup flag was deprecated and that tap trust became required in Homebrew commit `bc44e3d`. The merged change uses `--force-cleanup` and writes `trusted: true` into generated Brewfile entries. A reviewer said the new command “fails on older homebrew versions.” Issue 1794, “Refusing to load formula from untrusted tap,” is cited as fixed by the same pull request. — [nix-darwin pull request 1789](https://github.com/nix-darwin/nix-darwin/pull/1789)
- The locked nix-darwin source still appends `--cleanup` when `cleanup = "uninstall"`. It does not add `trusted: true`. This config’s taps include `wix/brew`, `lyft/formulae`, and `facebook/fb`, and `cleanup` is `"uninstall"`. — [module at `56c666e`](https://github.com/LnL7/nix-darwin/blob/56c666e108467d87d13508936aade6d567f2a501/modules/homebrew.nix); [darwin/homebrew.nix](file:///Users/khandkermahmudur/.config/nix/darwin/homebrew.nix)
- A September 2026 blog shows a macOS 27 `darwin-rebuild switch` log that prints `Homebrew bundle...` and then `` `brew bundle` complete! ``. The failure after that line is `failed to allocate`, attributed to `mac-app-util` and a Steel Bank Common Lisp build, with a flake `follows` change as the fix. That is a different macOS 27 nix-darwin failure, and it shows bundle completion on some macOS 27 machines. — [Alister Machado, 2026-09-15](https://amreis.github.io/misc/2026/09/15/macos27-nix-darwin.html)
- Determinate Systems’ nix-darwin guide says to set `nix.enable = false` so Determinate Nix owns the Nix installation, or to use the Determinate module. The guide does not mention Homebrew, Brewfile activation, or macOS 27 version detection. This repo already sets `nix.enable = false` with the comment that the Determinate installer is in use. — [Determinate nix-darwin guide](https://docs.determinate.systems/guides/nix-darwin/); [darwin/default.nix](file:///Users/khandkermahmudur/.config/nix/darwin/default.nix); [Determinate nix-darwin blog, 2025-02-19](https://determinate.systems/blog/nix-darwin-updates/)
- nix-homebrew issue 134, still open as of its 2026-05-01 update, asks to publish Homebrew into Nixpkgs as a package people could add to system packages. The maintainer replied that the heavy lifting is the nix-darwin module that sets up the Homebrew prefix, and that a derivation alone does not install Homebrew the way a system package would. — [nix-homebrew issue 134](https://github.com/zhaofengli/nix-homebrew/issues/134)

### Inferences

- The documented fix for this error is a newer Homebrew, delivered through the nix-homebrew `brew-src` pin. `brew update` is not available on this nix-managed install, which issue 152 records directly. `homebrew.onActivation.autoUpdate = false` also asks the activation script to set `HOMEBREW_NO_AUTO_UPDATE=1`, so a switch will not refresh Homebrew even when the `brew` binary is new enough to update itself.
- Copying only the issue 152 input override (`brew-src` → 6.0.1) onto nix-darwin `56c666e` leaves this config sending `--cleanup` and omitting `trusted: true`, including for the three non-official taps. Pull request 1789 exists because those Homebrew 6 behavior changes break the older module. A Homebrew-only bump can remove `:dunno` and then fail bundle for cleanup or trust. The searches did not include a run that proves the exact next error on 6.0.1.
- Searches for a nix-darwin issue with this error text, and for a Determinate Systems note about it, returned the nix-homebrew issue, the Homebrew pull request, and unrelated nix-darwin macOS 27 material. That is a search result, not a certificate that no issue exists.

### Gaps

- nix-darwin issues and Determinate Systems issues were not exhaustively listed. The queries used were `nix-darwin macOS 27 homebrew dunno`, `repo:nix-darwin/nix-darwin dunno OR "macOS 27" homebrew`, and `Determinate Systems nix-darwin macOS 27 homebrew`.
- Whether Homebrew 6.0.1 rejects `--cleanup` or only warns was not read from the Homebrew commit. Pull request 1789 describes the flag as deprecated and changes nix-darwin to `--force-cleanup`.
- Nixpkgs revision `a0991c886dc83e6e9de01d5266e4842985b1850e` was not searched file by file for a Homebrew package. See the next section.

## Is there a Nix-provided Homebrew package, separate from nix-homebrew, that already supports macOS 27?

### Takeaway

No Nixpkgs package that installs Homebrew and understands macOS 27 was found. The project that actually ships a pinned Homebrew derivation is nix-homebrew, and the pin in this lock is tag 5.1.11, which does not know macOS 27. Moving that pin to 6.0.1 is the Homebrew update. It is a different lever from skipping the bundle step, and on this config it should be paired with a nix-darwin that understands Homebrew 6 bundle flags.

### Cited Findings

- nix-homebrew provides Homebrew as a derivation and a nix-darwin module that sets up the prefix. The maintainer said adding that derivation to system packages does not set up Homebrew. Issue 134, the request to put that into Nixpkgs, was open on 2026-05-01. — [nix-homebrew issue 134](https://github.com/zhaofengli/nix-homebrew/issues/134); [nix-homebrew README](https://github.com/zhaofengli/nix-homebrew)
- Nixpkgs `pkgs/top-level/darwin-packages.nix` is the Darwin toolchain and software development kit scope (Apple command-line tools, compilers, and related libraries). It is not a Homebrew installation. Other Nixpkgs hits are patches that stop individual builds from calling `brew`. — [darwin-packages.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/darwin-packages.nix); [libresprite pull request 498574](https://github.com/NixOS/nixpkgs/pull/498574)
- A fetch of the Nixpkgs unstable package search for `homebrew` returned the search page shell and no package entry. — [search.nixos.org query `homebrew`](https://search.nixos.org/packages?channel=unstable&query=homebrew&type=packages)
- Homebrew 6.0.0 (2026-06-11) is the release note that announces initial macOS 27 support. nix-homebrew pull request 154 moves its default `brew-src` from 5.1.14 to 6.0.1. This lock is still `5.1.11`. — [Homebrew 6.0.0](https://brew.sh/2026/06/11/homebrew-6.0.0/); [nix-homebrew issue 152](https://github.com/zhaofengli/nix-homebrew/issues/152); [flake.lock](file:///Users/khandkermahmudur/.config/nix/flake.lock)

Comparison of the levers that were actually documented:

| Lever | What it changes | Effect on this `:dunno` failure | What the rest of the switch loses |
| --- | --- | --- | --- |
| `homebrew.enable = false` | Removes the bundle activation script at the locked nix-darwin revision | The `brew bundle` process never starts, so this Homebrew error is not reached | Declared brews, casks, taps, and `cleanup = "uninstall"` stop being applied. nix-homebrew can stay enabled and keep the Homebrew prefix. `/opt/homebrew/bin` remains on `systemPath` in this repo |
| `homebrew.onActivation.extraEnv.HOMEBREW_MACOS_VERSION` | Documented generic environment injection for the bundle command | Not a documented macOS version override. Homebrew 5.1.14 and current `main` replace the variable from `sw_vers` | Nothing else in the switch, and the version error remains if Homebrew ignores the preset value |
| Empty `brews` / `casks` / `taps` | Still runs `brew bundle` | Does not skip the command. With `cleanup = "uninstall"`, the module documents uninstalling anything absent from the Brewfile | Can remove existing Homebrew packages |
| Update nix-homebrew `brew-src` to Homebrew 6.0.1, or update nix-homebrew past pull request 154 | Replaces the pinned Homebrew that lacks a macOS 27 symbol | This is the fix recorded in nix-homebrew issue 152. `brew update` cannot do it while the install is nix-managed | On nix-darwin `56c666e`, bundle still passes `--cleanup` and does not mark taps trusted. Homebrew 6 changed both. Pull request 1789 is the nix-darwin side of that change |
| Update nix-darwin to a revision that contains pull request 1789, together with Homebrew 6.0.1 or newer | Aligns the activation command with Homebrew 6 and uses a Homebrew that has `golden_gate` | Addresses both the missing macOS 27 symbol and the cleanup/trust breakage that a Homebrew-only bump can expose | Needs a newer nix-darwin than `56c666e`. A reviewer of pull request 1789 said the new command fails on older Homebrew, so the nix-darwin bump and the Homebrew bump belong together |

### Inferences

- There is no second Nixpkgs Homebrew to switch to in place of nix-homebrew. The Homebrew that runs during the switch is the one nix-homebrew pinned, and that pin is older than the macOS 27 support release.
- Skipping the bundle is the lever that lets the rest of this switch finish without a newer Homebrew. Updating Homebrew is the lever that lets the bundle step succeed. For this file, the update includes a nix-darwin new enough for Homebrew 6’s `--force-cleanup` and tap trust, because cleanup is `"uninstall"` and three taps are not `homebrew/core`.

### Gaps

- No directory listing of Nixpkgs revision `a0991c88` was made, so a Homebrew package added on that exact commit would have been missed. The May 2026 request to add one was still open, and package search plus the Darwin package set did not show one.
- Homebrew 6.0.1 was not executed against this Brewfile, so the trust and `--cleanup` follow-on failure is inferred from nix-darwin issues 1787 and 1794 and pull request 1789, not from a local switch log.
