# nix-homebrew and the macOS 27 `:dunno` error

A user can point the nix-homebrew Nix flake input at a revision that already vendors Homebrew 6.0.22 or 7.0.4; both of those Homebrew tags contain the macOS 27 name `golden_gate`, which Homebrew 5.1.11 does not.

Observed on 2026-10-19. The nix-homebrew default branch commit is `c11cccfdd36dd69b5323d70d354b2853379c2426` (committed 2026-09-20T18:14:01Z, merge of pull request 182). Its Homebrew source input is tag `7.0.4`, git revision `edb70f031e4170c780799633a1226ff73e1077f4`. The local flake still follows nix-homebrew revision `b3a87b4793205cc111f3c61e25e018ffac3b8039`, whose flake input address is `github:Homebrew/brew/5.1.11`.

## Does current nix-homebrew master (as of 2026-10-19) still follow a brew tag that lacks macOS 27, or has brew-src moved to a tag/commit that includes macOS 27?

### Takeaway

Master has moved to Homebrew 7.0.4, and that tag maps macOS 27 to the symbol `golden_gate`. The installed Homebrew 5.1.11 map stops at macOS 26 (`tahoe`) and returns the fallback symbol `:dunno` for 27.

### Cited Findings

- nix-homebrew selects Homebrew by a non-flake input named `brew-src`. On master, that input address is `github:Homebrew/brew/7.0.4` with `flake = false`. The module then sets `nix-homebrew.package` to that source and names it `brew-` plus the `ref` recorded in nix-homebrew's own `flake.lock`. — [flake.nix](https://raw.githubusercontent.com/zhaofengli/nix-homebrew/master/flake.nix)
- The master lock records `brew-src` original ref `7.0.4`, revision `edb70f031e4170c780799633a1226ff73e1077f4`, `lastModified` `1789661079`, and content hash (narHash) `sha256-geVTQ51PGZ1mLULM5k7wO7qt/6xenOR/YG8X7Q3eCaI=`. The GitHub tag `7.0.4` points at that same revision. — [flake.lock](https://raw.githubusercontent.com/zhaofengli/nix-homebrew/master/flake.lock); [tag 7.0.4](https://github.com/Homebrew/brew/releases/tag/7.0.4)
- Master commit `c11cccfdd36dd69b5323d70d354b2853379c2426` is the merge of pull request 182, message "nix(deps): bump brew-src from 6.0.22 to 7.0.4", committed 2026-09-20T18:14:01Z. — [commit c11cccf](https://github.com/zhaofengli/nix-homebrew/commit/c11cccfdd36dd69b5323d70d354b2853379c2426)
- Homebrew 7.0.4 `Library/Homebrew/macos_version.rb` contains `golden_gate: "27"` and `tahoe: "26"`. Unknown majors still fall through `SYMBOLS.invert.fetch(strip_patch.to_s, :dunno)`. — [macos_version.rb at 7.0.4](https://github.com/Homebrew/brew/blob/7.0.4/Library/Homebrew/macos_version.rb)
- Homebrew 6.0.1 and 6.0.22 have the same `golden_gate: "27"` entry. — [macos_version.rb at 6.0.1](https://github.com/Homebrew/brew/blob/6.0.1/Library/Homebrew/macos_version.rb); [macos_version.rb at 6.0.22](https://github.com/Homebrew/brew/blob/6.0.22/Library/Homebrew/macos_version.rb)
- Homebrew 5.1.11's symbol table starts at `tahoe: "26"`, then `sequoia: "15"`, `sonoma: "14"`, `ventura: "13"`, `monterey: "12"`, `big_sur: "11"`, and `catalina: "10.15"`. There is no `golden_gate` entry. Line 140 uses the same `:dunno` fallback. — [macos_version.rb at 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/macos_version.rb)
- Homebrew pull request 22592, "Preliminary macOS 27 (Golden Gate) support", merged 2026-06-09 (merge commit `e7ef812873a9fc819ecdd78c417d49e9bc390469`). The Homebrew 6.0.0 announcement on 2026-06-11 says Homebrew adds initial support for macOS 27 (Golden Gate). — [Homebrew pull request 22592](https://github.com/Homebrew/brew/pull/22592); [Homebrew 6.0.0](https://brew.sh/2026/06/11/homebrew-6.0.0/)
- The local nix-homebrew revision `b3a87b4793205cc111f3c61e25e018ffac3b8039` still sets `brew-src.url` to `github:Homebrew/brew/5.1.11` and reads the displayed version from that revision's own lock file. — [flake.nix at b3a87b4](https://github.com/zhaofengli/nix-homebrew/blob/b3a87b4793205cc111f3c61e25e018ffac3b8039/flake.nix)
- nix-darwin revision `56c666e108467d87d13508936aade6d567f2a501` file `modules/homebrew.nix` has no match for `nix-homebrew`, `HOMEBREW_VERSION`, or `brew version`. nix-homebrew's readme points formula and cask management at the nix-darwin `homebrew.enable` options and does not say nix-darwin chooses the Homebrew version. — [nix-homebrew README](https://github.com/zhaofengli/nix-homebrew/blob/master/README.md)

### Inferences

- Updating the unpinned input `github:zhaofengli/nix-homebrew` locks master at `c11cccfdd36dd69b5323d70d354b2853379c2426` and Homebrew 7.0.4, which already contains the macOS 27 symbol. That removes the `:dunno` lookup that Homebrew 5.1.11 hits.
- The last nix-homebrew commit that still vendors the Homebrew 6.0 line is `09a921d0181146cf6163ec2cc1db7b6fd539a885` (2026-09-09T19:17:19Z, merge of pull request 181). Its lock uses Homebrew tag `6.0.22`, revision `08e85c4e42f5d8f1ea17c36cb59cf61c2ccb26c3`, content hash (narHash) `sha256-NbwVKwKLFl0oXub7oPjvmDaOygCtV2oboeKTu4xXFTk=`. That tag also contains `golden_gate: "27"`. — [flake.lock at 09a921d](https://github.com/zhaofengli/nix-homebrew/blob/09a921d0181146cf6163ec2cc1db7b6fd539a885/flake.lock)
- Exact input that stays on that 6.0.22 revision:

```nix
nix-homebrew.url = "github:zhaofengli/nix-homebrew/09a921d0181146cf6163ec2cc1db7b6fd539a885";
```

- Leaving the address as `github:zhaofengli/nix-homebrew` and updating the lock moves to master `c11cccfdd36dd69b5323d70d354b2853379c2426` / Homebrew 7.0.4. That also has the macOS 27 name. See the open activation report in the third question before choosing master over `09a921d`.

### Gaps

- The local lock's Homebrew revision `6f293daa9f9f5832e13b497976335e90509886d7` was not re-read from `flake.lock` in this pass. The remote nix-homebrew revision cited above does address Homebrew tag `5.1.11`.
- The rendered nix-darwin manual page was not opened. Only `modules/homebrew.nix` at the pinned revision was searched.

## Can a user override only the brew-src input (for example `nix-homebrew.inputs.brew-src.url`) without waiting for nix-homebrew, and is that a supported pattern in the nix-homebrew README?

### Takeaway

Yes, a Nix flake input override of `nix-homebrew.inputs.brew-src` changes the Homebrew source without a nix-homebrew release. The README does not document that pattern. The package version string stays whatever nix-homebrew's own lock file says.

### Cited Findings

- The master README shows `nix-homebrew.url = "github:zhaofengli/nix-homebrew"` and optional `homebrew-core` / `homebrew-cask` inputs. It does not mention `brew-src`, `inputs.brew-src.url`, or `follows`. — [README](https://raw.githubusercontent.com/zhaofengli/nix-homebrew/master/README.md)
- On 2026-06-12, in issue 152, kevinastone gave this override as the way to reach Homebrew 6.0.1 before nix-homebrew merged it: `nix-homebrew.inputs.brew-src.url = "github:Homebrew/brew/6.0.1";`. The reporter replied that it was the needed hint. The maintainer then closed the issue because pull request 154 had landed. — [issue 152](https://github.com/zhaofengli/nix-homebrew/issues/152)
- Issue 135 shows a second, older form that follows a separate input: `inputs.brew-src.follows = "homebrew-brew"` with `homebrew-brew.url = "github:Homebrew/brew/5.0.16"`. A commenter noted that snippet also changed the nix-homebrew owner to `zhaofengli-wip`. — [issue 135](https://github.com/zhaofengli/nix-homebrew/issues/135)
- Both the user's pinned revision and master compute the version with `brewVersion = flakeLock.nodes.brew-src.original.ref` after `builtins.readFile ./flake.lock` inside the nix-homebrew source. The package is `brew-src // { name = "brew-${brewVersion}"; version = brewVersion; }`. An input override replaces the `brew-src` argument. It does not rewrite that lock file, so the stamped version remains the tag name inside nix-homebrew. — [flake.nix at b3a87b4](https://github.com/zhaofengli/nix-homebrew/blob/b3a87b4793205cc111f3c61e25e018ffac3b8039/flake.nix); [flake.nix on master](https://github.com/zhaofengli/nix-homebrew/blob/master/flake.nix)

### Inferences

- On the current local pin, this override changes the Ruby sources while the Nix package name stays `brew-5.1.11` until nix-homebrew itself is updated:

```nix
nix-homebrew.inputs.brew-src.url = "github:Homebrew/brew/6.0.22";
```

- `6.0.22` is the concrete tag that already contains `golden_gate: "27"` and matches the last Homebrew 6.0 revision nix-homebrew shipped (`09a921d`). `6.0.1` is the oldest tag the issue 152 comment used. Homebrew 7.0.4 also has the symbol, with the activation caveat in the next question.
- The macOS symbol table lives in the overridden source, so the `:dunno` lookup changes even if the stamped version string is still `5.1.11`.
- Prefer moving the whole `nix-homebrew` input to `09a921d0181146cf6163ec2cc1db7b6fd539a885` when the goal is one lock update. That keeps the Homebrew tag, the copied `bin/brew` tail, and the version string on the same revision.

### Gaps

- No nix-homebrew test or README sentence was found that says the override is a supported interface. The evidence is two issue comments plus ordinary Nix flake input overriding.
- It was not built here, so the override was not confirmed to evaluate against the local flake.

## Are there open or merged issues/PRs in zhaofengli/nix-homebrew about macOS 26, macOS 27, `:dunno`, or unsupported macOS?

### Takeaway

The `:dunno` report on macOS 27 is closed issue 152, fixed by merged pull request 154 (Homebrew 5.1.14 to 6.0.1). macOS 26 support was claimed in merged pull request 116. Master is now Homebrew 7.0.4, and open issue 187 says that bump breaks activation.

### Cited Findings

- Issue 152, "Error: unknown or unsupported macOS version: :dunno", opened 2026-06-12, closed 2026-06-13. The report is macOS 27. `brew update-reset` prints `Warning: No remote 'origin' in /opt/homebrew/Library/.homebrew-is-managed-by-nix, skipping update and reset!`. Maintainer zhaofengli: "This is now fixed by #154 which upgrades brew to 6.0.1." — [issue 152](https://github.com/zhaofengli/nix-homebrew/issues/152)
- Pull request 154, "brew-src: 5.1.14 -> 6.0.1", merged 2026-06-12T13:05:51Z, merge commit `5e721fc7756a6abffe07c7dd5ed3f9080b68108f`. Body: "This release includes preliminary support for macOS 27 Golden Gate." — [pull request 154](https://github.com/zhaofengli/nix-homebrew/pull/154)
- Pull request 116, "brew-src: 4.6.7 -> 4.6.12", merged 2025-09-23T03:30:28Z. Body: "Upstream now officially supports macOS 26 Tahoe." — [pull request 116](https://github.com/zhaofengli/nix-homebrew/pull/116)
- Issue 146 is open. On macOS 26.2 with `autoMigrate = true`, activation dies with `/bin/bash: /opt/homebrew/Library/Homebrew/brew.sh: No such file or directory`. That is a migration failure, separate from `:dunno`. — [issue 146](https://github.com/zhaofengli/nix-homebrew/issues/146)
- Issue 155, closed, reports activation failure after the Homebrew 6.0.1 update, including `Homebrew bundle...` and a deprecated `--cleanup` warning. The maintainer called it a nix-darwin issue and linked a workaround. — [issue 155](https://github.com/zhaofengli/nix-homebrew/issues/155)
- Issue 187, "brew 7.0.4 breaks activation: bin/brew shim missing HOMEBREW_ORIGINAL_BREW_FILE export", opened 2026-09-24, still open, updated 2026-10-18. The report says `darwin-rebuild switch` fails at `Homebrew bundle...` with `KeyError` for `HOMEBREW_ORIGINAL_BREW_FILE` in `startup/config.rb:36` of `brew-7.0.4-patched`, on nix-homebrew `c11cccfdd36dd69b5323d70d354b2853379c2426`. The suggested workaround in that issue is to pin nix-homebrew to `09a921d0181146cf6163ec2cc1db7b6fd539a885` (Homebrew 6.0.x). — [issue 187](https://github.com/zhaofengli/nix-homebrew/issues/187)
- Homebrew tag 7.0.4 `Library/Homebrew/startup/config.rb` fetches `HOMEBREW_BREW_FILE` and does not contain the string `HOMEBREW_ORIGINAL_BREW_FILE`. Tag 7.0.4 `bin/brew` also has no `HOMEBREW_ORIGINAL_BREW_FILE` match. The master nix-homebrew file `modules/brew.tail.sh` at `c11cccf` likewise has no `HOMEBREW_ORIGINAL_BREW_FILE` match. The tail at `09a921d` and at the local pin `b3a87b4` both contain `export HOMEBREW_ORIGINAL_BREW_FILE="${HOMEBREW_BREW_FILE}"`. — [config.rb at 7.0.4](https://github.com/Homebrew/brew/blob/7.0.4/Library/Homebrew/startup/config.rb); [brew.tail.sh at 09a921d](https://github.com/zhaofengli/nix-homebrew/blob/09a921d0181146cf6163ec2cc1db7b6fd539a885/modules/brew.tail.sh); [brew.tail.sh at b3a87b4](https://github.com/zhaofengli/nix-homebrew/blob/b3a87b4793205cc111f3c61e25e018ffac3b8039/modules/brew.tail.sh)
- Open pull request 193 is titled "nix(deps): bump brew-src from 7.0.4 to 7.0.9". Master is still 7.0.4. Closed bump pull requests 188 (7.0.6) and 191 (7.0.8) also did not change the master lock observed here. — [pull request 193](https://github.com/zhaofengli/nix-homebrew/pull/193)
- Issue 135, closed 2026-05-15, says the then-default Homebrew 4.5.6 crashes casks that use bare `depends_on :macos`, with `unknown or unsupported macOS version: ":"`. Comment: pull request 141 upgrades to 5.1.11. Maintainer: "Yes, this should be fixed." — [issue 135](https://github.com/zhaofengli/nix-homebrew/issues/135)

### Inferences

- The merged fix for this exact `:dunno` error has been on nix-homebrew since 2026-06-12 (pull request 154). The local pin is older than that fix.
- `09a921d` is the pin issue 187 itself offers, and its Homebrew 6.0.22 sources include macOS 27. Moving there gets the symbol table and keeps the launcher tail that still exports `HOMEBREW_ORIGINAL_BREW_FILE`.
- Issue 187 and the Homebrew 7.0.4 file disagree on the missing key. The activation failure was not reproduced in this pass, so master `c11cccf` / Homebrew 7.0.4 should be treated as an open risk, while the presence of `golden_gate` in that tag is confirmed.

### Gaps

- Pull request 193's diff was not read, so it is only known as an unmerged 7.0.4 to 7.0.9 title.
- No second `:dunno` issue was found. Search hits for "macOS" also include unrelated open bugs (migration, casks, taps).

## What does the nix-homebrew patch set do to upstream brew, and would bumping brew-src risk the patch failing to apply?

### Takeaway

The patch is a small build-time edit, on by default, that disables Homebrew self-update, forces the Nix Ruby, and stamps the version because the Nix copy has no git history. That edit still matches Homebrew 7.0.4's update script. The separate risk is the hand-copied `bin/brew` tail, which master no longer keeps in step with the 6.0.22 tail.

### Cited Findings

- `patchBrew` defaults to true ("Whether to attempt to patch Homebrew to suppress self-updating"). When on, the package name becomes `brew-<version>-patched`. The activation script symlinks `Library/Homebrew` at the prefix to that store path. — [modules/default.nix](https://github.com/zhaofengli/nix-homebrew/blob/c11cccfdd36dd69b5323d70d354b2853379c2426/modules/default.nix)
- The patch does four things in `modules/default.nix`: copy the upstream tree; `substituteInPlace` `cmd/update.sh` with `--replace-fail` so `for DIR in "${HOMEBREW_REPOSITORY}"` becomes `for DIR in `; if `utils/ruby.sh` contains `setup-ruby-path`, append a function that sets `HOMEBREW_RUBY_PATH` to Nixpkgs Ruby 4.0 (`pkgs.ruby_4_0` on this master file) and prepend that Ruby's `fiddle` gem onto the load path; `sed` `brew.sh` so `HOMEBREW_VERSION=` and `GIT_REVISION=` are replaced with the locked version and an empty git revision. — [modules/default.nix](https://github.com/zhaofengli/nix-homebrew/blob/c11cccfdd36dd69b5323d70d354b2853379c2426/modules/default.nix)
- The string `for DIR in "${HOMEBREW_REPOSITORY}"` is present in `cmd/update.sh` at Homebrew 5.1.11 (lines 717 and 952), 6.0.22 (lines 725 and 1007), and 7.0.4 (lines 726 and 1008). `--replace-fail` therefore still has a match on those tags. — [update.sh at 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/cmd/update.sh); [update.sh at 7.0.4](https://github.com/Homebrew/brew/blob/7.0.4/Library/Homebrew/cmd/update.sh)
- Issue 187's traceback names a built Nix store path `brew-7.0.4-patched`, so the patch build was produced for that bump. The reported failure is later, when the launcher runs. — [issue 187](https://github.com/zhaofengli/nix-homebrew/issues/187)
- `modules/brew.tail.sh` is a copy of upstream `bin/brew`, with the comment "Run scripts/update-brew-tail.sh to update this". Prefix `bin/brew` is a generated script that sets `HOMEBREW_PREFIX`, `HOMEBREW_LIBRARY`, `HOMEBREW_REPOSITORY`, and `HOMEBREW_BREW_FILE`, then appends that tail. — [modules/default.nix](https://github.com/zhaofengli/nix-homebrew/blob/c11cccfdd36dd69b5323d70d354b2853379c2426/modules/default.nix); [brew.tail.sh](https://github.com/zhaofengli/nix-homebrew/blob/master/modules/brew.tail.sh)
- Local `darwin/homebrew.nix` sets `homebrew.onActivation.upgrade = false` with a comment that the patched Homebrew errors in formula postinstall for some upgraded packages (examples given: ollama, watchman). Separate comments say the casks `wezterm` and `zulu@17` are incompatible with patched Homebrew 4.5.6. The running package name in this investigation is `brew-5.1.11-patched`. — [darwin/homebrew.nix](file:///Users/khandkermahmudur/.config/nix/darwin/homebrew.nix)
- Issue 135's Homebrew 4.5.6 cask crash (`depends_on :macos`) was closed as fixed by the move to Homebrew 5.1.11. That crash text is `unknown or unsupported macOS version: ":"`, which is a different string from `:dunno`. — [issue 135](https://github.com/zhaofengli/nix-homebrew/issues/135)

### Inferences

- Bumping `brew-src` from 5.1.11 to 6.0.22 or 7.0.4 is unlikely to fail the `update.sh` `--replace-fail` step, because the replaced text is still there. The Ruby edit is skipped when `setup-ruby-path` is absent, so a missing hook would not fail the build.
- The `sed` on `HOMEBREW_VERSION=` / `GIT_REVISION=` does not use a failing replace. A changed `brew.sh` would leave those lines alone and the build would still succeed.
- The launcher tail is not part of `patchBrew`. Overriding only `brew-src` on the local pin keeps the 5.1.11-era tail, which does export `HOMEBREW_ORIGINAL_BREW_FILE`. Updating nix-homebrew to master replaces that tail with the `c11cccf` copy, which does not export it. That is the drift issue 187 describes, even though the 7.0.4 `config.rb` read here does not fetch that variable.
- The comments that name patched Homebrew 4.5.6 are stale relative to the locked 5.1.11 package. The unversioned postinstall comment was not matched to a Homebrew 5.1.11 report.

### Gaps

- `brew.sh` lines `HOMEBREW_VERSION=` and `GIT_REVISION=` were not re-read at 6.0.22 or 7.0.4, so a silent `sed` miss is possible.
- The Ruby version pinned inside nix-homebrew revision `b3a87b4` was not compared with `pkgs.ruby_4_0` on master. An override of `brew-src` alone keeps the Ruby the old module injects.
- No source confirmed that ollama, watchman, wezterm, or `zulu@17` still fail on `brew-5.1.11-patched`. Issue 135 covers a 4.5.6 cask-loader bug the maintainer said the 5.1.11 bump fixes; it does not name those four packages.
