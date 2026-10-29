# Homebrew macOS 27 upstream support

These notes identify the Homebrew release that first recognizes macOS 27, and what an older Homebrew copy does when it sees that version. Sources were opened on 2026-10-19. The default branch of Homebrew/brew is `main`. A raw fetch of the old `master` branch path returned HTTP 404.

## Which commit and tag first add a macOS 27 symbol, and what codename did they use?

### Takeaway

Commit `2cf6d634d4a9dc358009938981aed10bcb16920a` (2026-06-08) is the first commit that adds the symbol. It maps `golden_gate` to `"27"` in `Library/Homebrew/macos_version.rb` and maps numeric versions at or above `270000` to the same name in `Library/Homebrew/cmd/update.sh`. The codename in the pull request and the 6.0.0 announcement is Golden Gate. That commit was merged to the default branch as `e7ef812873a9fc819ecdd78c417d49e9bc390469` (2026-06-09) and first shipped in stable tag `6.0.0` (published 2026-06-11).

### Cited Findings

- Pull request 22592, “Preliminary macOS 27 (Golden Gate) support”, by Bo98, was merged on 2026-06-09T00:51:12Z. The merge commit is `e7ef812873a9fc819ecdd78c417d49e9bc390469`. — [Pull request 22592](https://github.com/Homebrew/brew/pull/22592)
- The pull request has two commits. The first, `2cf6d634d4a9dc358009938981aed10bcb16920a` (2026-06-08T22:21:05Z), message “Preliminary macOS 27 (Golden Gate) support”, edits `Library/Homebrew/macos_version.rb` and `Library/Homebrew/cmd/update.sh`. The second, `7750fa03645dc7b72f35dfde2d766bea3b006866` (2026-06-09T00:07:02Z), message “api: fallback to latest OS when prerelease OS doesn't exist”, is the later application-programming-interface fallback and is not the commit that adds the symbol. — [Commit 2cf6d634](https://github.com/Homebrew/brew/commit/2cf6d634d4a9dc358009938981aed10bcb16920a); [Commit 7750fa03](https://github.com/Homebrew/brew/commit/7750fa03645dc7b72f35dfde2d766bea3b006866)
- The merged symbol table at tag `6.0.0` is in `Library/Homebrew/macos_version.rb`:

  | Symbol | Version string |
  | --- | --- |
  | `golden_gate` | `"27"` |
  | `tahoe` | `"26"` |
  | `sequoia` | `"15"` |
  | `sonoma` | `"14"` |
  | `ventura` | `"13"` |
  | `monterey` | `"12"` |
  | `big_sur` | `"11"` |
  | `catalina` | `"10.15"` |

  The file comment says this list must match `macos_version_name` in `cmd/update.sh`. — [macos_version.rb at tag 6.0.0](https://github.com/Homebrew/brew/blob/6.0.0/Library/Homebrew/macos_version.rb)
- At tag `6.0.0`, `macos_version_name` in `Library/Homebrew/cmd/update.sh` echoes `golden_gate` when `HOMEBREW_MACOS_VERSION_NUMERIC` is at least `270000`, and `tahoe` when it is at least `260000`. `bottle_tag` prints that name for Intel `x86_64`, and prints the processor plus that name otherwise (`arm64_golden_gate` on Apple silicon). — [update.sh at tag 6.0.0](https://github.com/Homebrew/brew/blob/6.0.0/Library/Homebrew/cmd/update.sh)
- The same first commit also adds software-development-kit pkg-config files under `Library/Homebrew/os/mac/pkgconfig/27/` (bzip2, expat, libcurl, libedit, libexslt, libffi, libxml-2.0, libxslt, ncurses, ncursesw, sqlite3, uuid, zlib), maps macOS `"27"` to Clang `2100.3.20.102` in `Library/Homebrew/os/mac/xcode.rb`, and adds bottle test fixtures named `golden_gate` and `arm64_golden_gate`. — [Commit 2cf6d634](https://github.com/Homebrew/brew/commit/2cf6d634d4a9dc358009938981aed10bcb16920a)
- Kernel major mapping in that commit: marketing major `27` or newer uses the marketing major as the kernel major (`"27"`); marketing major `26` uses `25` (`version_major - 1`); majors `11` through `25` still use `version_major + 9`. Tag `5.1.11` had used `version_major - 1` for every marketing major at or above `26`, which would have mapped macOS 27 to kernel major `26`. — [Pull request 22592 file patch](https://github.com/Homebrew/brew/pull/22592); [macos_version.rb at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/macos_version.rb)
- Tag `5.1.11` points at commit `6f293daa9f9f5832e13b497976335e90509886d7` (commit date 2026-05-10T15:40:48Z, tag published 2026-05-11T07:25:58Z). Its `SYMBOLS` hash ends at `tahoe: "26"`. `to_sym` uses `SYMBOLS.invert.fetch(strip_patch.to_s, :dunno)`. `from_symbol` is at line 50 and raises `MacOSVersion::Error` when the symbol is missing. The error initializer sets the message to `unknown or unsupported macOS version: #{version.inspect}`, so the symbol is printed as `:dunno`. — [Tag 5.1.11](https://github.com/Homebrew/brew/releases/tag/5.1.11); [macos_version.rb at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/macos_version.rb)
- In tag `5.1.11`, `Library/Homebrew/brew.sh` sets `HOMEBREW_MACOS_NEWEST_UNSUPPORTED="27"` and `HOMEBREW_MACOS_NEWEST_SUPPORTED="26"`. `prerelease?` is `self >= HOMEBREW_MACOS_NEWEST_UNSUPPORTED`. — [brew.sh at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/brew.sh)
- On the macOS-specific override, `Homebrew::SimulateSystem.current_os` is `::Homebrew::SimulateSystem.os || MacOS.version.to_sym` (`Library/Homebrew/extend/os/mac/simulate_system.rb` at tag `5.1.11`). A macOS 27 version whose stripped major is absent from `SYMBOLS` therefore yields `:dunno`. — [simulate_system.rb at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/extend/os/mac/simulate_system.rb)
- The 6.0.0 announcement by Mike McQuaid (11 June 2026) says: “Homebrew adds initial support for macOS 27 (Golden Gate).” — [Homebrew 6.0.0 announcement](https://brew.sh/2026/06/11/homebrew-6.0.0/)

### Inferences

- Tag `5.1.11` matches the local copy: the symbol table stops at Tahoe (`tahoe` / `"26"`), so macOS 27.0.1 becomes `:dunno`, and `from_symbol(:dunno)` raises the quoted error.
- On tag `5.1.11`, `cmd/update.sh` still treats every numeric version at or above `260000` as `tahoe`. Product version `27.0.1` formats as `270001`, so the shell bottle name is Tahoe while the Ruby symbol is `:dunno`. The 6.0.0 shell function is what makes those two tables agree on `golden_gate`.

### Gaps

- Whether `kernel_major_version` returning `"27"` for marketing major 27 matches the Darwin kernel on the local machine was not checked. The local build string supplied with this task is `26A434`.
- `Library/Homebrew/cmd/update.sh` was opened at tags `5.1.11` and `6.0.0`. It was not re-opened at tag `7.0.10` or on `main`.
- The Ruby method that calls `from_symbol` during `brew upgrade` was not opened. The raise site and the `:dunno` value of `current_os` were opened, and the issue transcripts below show `brew upgrade` printing the error.

## Is that commit in a stable tag newer than 5.1.11, or only on the default branch as of 2026-10-19?

### Takeaway

The symbol commit is in stable tags. The first stable tag is `6.0.0` (2026-06-11). It is not only on the default branch. As of 2026-10-19 the newest stable tag is `7.0.10` (published 2026-10-19T13:06:46Z), and `golden_gate: "27"` is still present there and on `main`.

### Cited Findings

- Comparing `e7ef812873a9fc819ecdd78c417d49e9bc390469` to tag `6.0.0` (`3d9e344622974a7f96da927fd0407e08581eb437`) reports `status` `ahead`, `behind_by` 0, `ahead_by` 109. Tag `6.0.0` therefore contains the merge. Comparing the same merge to tag `5.1.15` reports `ahead_by` 0 and `behind_by` 164, so tag `5.1.15` does not contain it. — [Compare merge to 6.0.0](https://github.com/Homebrew/brew/compare/e7ef812873a9fc819ecdd78c417d49e9bc390469...6.0.0); [Compare merge to 5.1.15](https://github.com/Homebrew/brew/compare/e7ef812873a9fc819ecdd78c417d49e9bc390469...5.1.15)
- Releases between the merge and the next major tag: `5.1.15` published 2026-06-03T13:24:35Z, then `6.0.0` published 2026-06-11T13:13:47Z, then `6.0.1` on 2026-06-12. The tag listing for `5.2` returned no refs. — [Homebrew/brew releases](https://github.com/Homebrew/brew/releases)
- Tag `6.0.0` still has `HOMEBREW_MACOS_NEWEST_UNSUPPORTED="27"` and `HOMEBREW_MACOS_NEWEST_SUPPORTED="26"`. Tag `6.0.22` (published 2026-09-05) still has those same two values. Tag `7.0.0` (published 2026-09-13T08:30:11Z) has `HOMEBREW_MACOS_NEWEST_UNSUPPORTED="28"` and `HOMEBREW_MACOS_NEWEST_SUPPORTED="27"`. — [brew.sh at tag 6.0.0](https://github.com/Homebrew/brew/blob/6.0.0/Library/Homebrew/brew.sh); [brew.sh at tag 6.0.22](https://github.com/Homebrew/brew/blob/6.0.22/Library/Homebrew/brew.sh); [brew.sh at tag 7.0.0](https://github.com/Homebrew/brew/blob/7.0.0/Library/Homebrew/brew.sh)
- The `7.0.0` release notes include “Promote macOS Golden Gate 27 to full support” by p-linnane, pull request 23928, merged 2026-09-10T22:56:43Z as `bf385de7eb8f516027cd3925bc292acb93055953`. They also include “Use GitHub runners for Golden Gate dependents”, pull request 23942. — [Release 7.0.0](https://github.com/Homebrew/brew/releases/tag/7.0.0); [Pull request 23928](https://github.com/Homebrew/brew/pull/23928)
- At tag `7.0.10`, `RELEASES` still starts with `golden_gate: "27"` and `tahoe: "26"`, and also keeps historical names through `el_capitan: "10.11"`. `SYMBOLS` is `RELEASES` except `:catalina`, `:mojave`, `:high_sierra`, `:sierra`, and `:el_capitan`, so `golden_gate` remains an active symbol. `from_symbol` still raises `MacOSVersion::Error` for a missing symbol. `kernel_major_version` still returns the marketing major for major `27` or newer. `main` on 2026-10-19 still contains the line `golden_gate: "27"`. — [macos_version.rb at tag 7.0.10](https://github.com/Homebrew/brew/blob/7.0.10/Library/Homebrew/macos_version.rb); [macos_version.rb on main](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/macos_version.rb); [Release 7.0.10](https://github.com/Homebrew/brew/releases/tag/7.0.10)

### Inferences

- Homebrew 6.0.0 through 6.0.22 can name macOS 27 (`golden_gate`) and so will not raise `:dunno`, while `prerelease?` stays true because the unsupported bound is still 27. Homebrew 7.0.0 and 7.0.10 keep the name and treat 27 as the newest supported release, with 28 as the unsupported bound.
- There is no stable 5.1 or 5.2 tag that contains the symbol. `5.1.15` (2026-06-03) is the last 5.1 release and predates the merge.

### Gaps

- The parent of `7750fa03645dc7b72f35dfde2d766bea3b006866` was not requested from the commit application programming interface. The pull-request commit list is the evidence that `2cf6d634` is the earlier of the two commits on that pull request.

## Does HOMEBREW_MACOS_VERSION=26 or 26.0 make from_symbol succeed on 5.1.11, and what do docs or issues say about bottles, casks, and the SDK?

### Takeaway

Exporting `HOMEBREW_MACOS_VERSION=26` or `26.0` before `brew` does not change the version Ruby sees on tag `5.1.11`, because `Library/Homebrew/brew.sh` assigns that variable from `/usr/bin/sw_vers -productVersion` on every run. If Ruby actually constructs the version from `"26"` or `"26.0"`, `to_sym` is `:tahoe` and `from_symbol(:tahoe)` succeeds. The variable that tag `5.1.11` reads for that override is `HOMEBREW_FAKE_MACOS`, and the Homebrew manual page that was searched does not document either variable. Issues describe the maintained fix as the Golden Gate pull request, which shipped in 6.0.0; they also contain user-suggested shims.

### Cited Findings

- At tag `5.1.11`, `Library/Homebrew/brew.sh` contains `HOMEBREW_MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"` with no test for an existing value, then derives `HOMEBREW_MACOS_VERSION_NUMERIC` with `printf -v ... "%02d%02d%02d"`. It later exports `HOMEBREW_MACOS_VERSION`. — [brew.sh at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/brew.sh)
- `OS::Mac::VERSION` is `ENV.fetch("HOMEBREW_MACOS_VERSION")`. `OS::Mac.full_version` uses `MacOSVersion.new(ENV["HOMEBREW_FAKE_MACOS"])` when that variable is present, and otherwise `MacOSVersion.new(VERSION)`. The comment says `HOMEBREW_FAKE_MACOS` is set in the macOS 11 Apple-silicon cross image used to build a macOS 11 portable Ruby. `OS::Mac.version` is `full_version.strip_patch`. — [os/mac.rb at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/os/mac.rb)
- At tag `6.0.0`, `MacOSVersion#initialize` raises `MacOSVersion::Error` unless the string matches `\A\d{2,}(?:\.\d+){0,2}\z`. The pull request 22592 patch for `macos_version.rb` does not change `initialize`. Both `"26"` and `"26.0"` match that expression. `strip_patch` returns the major component alone when the major is at least 11, so both strings become `"26"`. `SYMBOLS` on tag `5.1.11` maps that string back to `:tahoe`. `from_symbol(:tahoe)` loads `"26"`. `from_symbol(:dunno)` still raises, because `:dunno` is the missing-key fallback and is not a key. — [macos_version.rb at tag 6.0.0](https://github.com/Homebrew/brew/blob/6.0.0/Library/Homebrew/macos_version.rb); [macos_version.rb at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/macos_version.rb)
- A search of `docs/Manpage.md` at tag `7.0.10` found no `HOMEBREW_MACOS_VERSION` and no `HOMEBREW_FAKE_MACOS`. A repository code search for `HOMEBREW_FAKE_MACOS` hit `Library/Homebrew/os/mac.rb` and `Library/Homebrew/test/macos_version_spec.rb`. A code search for `HOMEBREW_MACOS_VERSION` in Markdown files returned no hits. — [Manpage.md at tag 7.0.10](https://github.com/Homebrew/brew/blob/7.0.10/docs/Manpage.md); [os/mac.rb](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/os/mac.rb)
- On tag `5.1.11`, a Ruby version of 26 follows the Tahoe bottle and cask name, which is the same name `cmd/update.sh` already emits for numeric `270001`. The macOS 27 pkg-config directory and the Clang `"27"` mapping are absent until commit `2cf6d634`. — [update.sh at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/cmd/update.sh); [Commit 2cf6d634](https://github.com/Homebrew/brew/commit/2cf6d634d4a9dc358009938981aed10bcb16920a)
- Commit `7750fa03645dc7b72f35dfde2d766bea3b006866` adds a fallback for the internal package application programming interface when the prerelease operating-system tag does not exist yet. The pull request overview says this lets prerelease systems run before the new internal JSON artifact is published. — [Commit 7750fa03](https://github.com/Homebrew/brew/commit/7750fa03645dc7b72f35dfde2d766bea3b006866); [Pull request 22592](https://github.com/Homebrew/brew/pull/22592)
- The 6.0.0 announcement states the Intel consequence of Golden Gate in the support tiers: in September 2026, macOS Intel `x86_64` moves to Tier 3, with no continuous-integration support and no new bottles built for macOS Intel; in September 2027, macOS Intel `x86_64` becomes unsupported and the related code is deleted. The pull request body, at merge time, left Intel handling as a pending note and said Rosetta would likely keep `golden_gate` and `arm64_golden_gate` tags, with macOS 28 as the point where that could be dropped. — [Homebrew 6.0.0 announcement](https://brew.sh/2026/06/11/homebrew-6.0.0/); [Pull request 22592](https://github.com/Homebrew/brew/pull/22592)

### Inferences

- A normal `brew` or `brew ruby` invocation on tag `5.1.11` still reports 27.0.1 after `HOMEBREW_MACOS_VERSION=26` or `26.0` is exported, so `current_os` stays `:dunno` and `from_symbol(:dunno)` still raises.
- `HOMEBREW_FAKE_MACOS=26` or `HOMEBREW_FAKE_MACOS=26.0` is the override `os/mac.rb` actually consults, and `brew.sh` was not seen assigning it. That path makes `current_os` equal `:tahoe`, so `from_symbol` succeeds. Bottle and cask selection then follows Tahoe. Source builds still see the macOS 26 software-development-kit shims that exist in 5.1.11, because the `pkgconfig/27` files arrive only with the Golden Gate commit.
- Forcing Tahoe on a macOS 27 machine asks Homebrew for Tahoe bottles. That is a version lie. The maintained way to get a `golden_gate` bottle tag, the macOS 27 pkg-config shims, and the internal-API fallback is Homebrew 6.0.0 or newer. Full support, meaning macOS 27 is no longer classified as a prerelease by `HOMEBREW_MACOS_NEWEST_UNSUPPORTED`, starts at 7.0.0.

### Gaps

- `HOMEBREW_MACOS_VERSION` and `HOMEBREW_FAKE_MACOS` were not executed against the local `brew-5.1.11-patched` install. The conclusion is from the tag `5.1.11` source.
- No Homebrew document opened here states the bottle or cask compatibility of pretending to be macOS 26 on macOS 27. The Tahoe-tag consequence is from the symbol table and `bottle_tag`.
- Whether homebrew-core had published `arm64_golden_gate` bottles on 2026-06-11, or only after pull request 23942, was not checked in homebrew-core.

## Which issues or pull requests describe :dunno on macOS 27 or a macOS 26 beta, and what fix do they give?

### Takeaway

The opened macOS 27 reports are issue 22606 and issue 22607, both on Homebrew 5.1.15, both closed. Maintainer p-linnane pointed issue 22607 at merged pull request 22592. The stable fix after 2026-06-11 is upgrading to tag `6.0.0` or newer. User comments suggested a `sw_vers` stand-in, resetting the brew checkout to `origin/master`, and `brew developer on`. No macOS 26 beta issue was opened for this note.

### Cited Findings

- Issue 22606, “MacOS 27 support”, by skadibtw, created 2026-06-08T22:24:38Z and closed 2026-06-08T22:25:46Z. `brew config` shows `HOMEBREW_VERSION: 5.1.15`, `macOS` implied by the doctor warning “You are using macOS 27.” The command transcript is `brew upgrade` ending in `Error: unknown or unsupported macOS version: :dunno`. The comments list was empty. — [Issue 22606](https://github.com/Homebrew/brew/issues/22606)
- Issue 22607, “Preliminary support for macOS 27”, by falchion10, created 2026-06-08T23:56:49Z and last updated 2026-06-10T01:44:37Z, state closed. `brew config` shows `HOMEBREW_VERSION: 5.1.15`, `HEAD: 863696a47f8d9292cb25084b6f8228e003084101`, branch `stable`, `macOS: 27.0-arm64`, Command Line Tools `27.0.0.0.1780650213`, Xcode `27.0`. The reported failure is `Error: unknown or unsupported macOS version: :dunno` from `brew upgrade`. Doctor also prints the Tier 2 prerelease warning for macOS 27. — [Issue 22607](https://github.com/Homebrew/brew/issues/22607)
- p-linnane commented on issue 22607 at 2026-06-09T00:26:41Z that the beta had been out for 6 hours, and linked pull request 22592. The issue was then closed. — [Issue 22607](https://github.com/Homebrew/brew/issues/22607)
- Later comments on issue 22607, after the merge and before tag `6.0.0`: victorwads posted a `~/fakebin/sw_vers` script that rewrites `27.` to `26.` and is placed first on `PATH` (2026-06-10T00:20:07Z). asptweets reported that `git checkout master` and `git reset --hard origin/master` in the brew repo, followed by `brew update` and `brew upgrade`, worked for them (2026-06-10T01:35:35Z). falchion10, the issue author, wrote “Please don't do either of these solutions” and posted `brew developer on` then `brew update && brew upgrade` (2026-06-10T01:43:02Z). — [Issue 22607](https://github.com/Homebrew/brew/issues/22607)
- Tag `5.1.11` calls `/usr/bin/sw_vers` by absolute path. A `sw_vers` placed earlier on `PATH` does not change that assignment. — [brew.sh at tag 5.1.11](https://github.com/Homebrew/brew/blob/5.1.11/Library/Homebrew/brew.sh)
- A code search for the `:dunno` error text also listed older closed issues 19462 (“Unknown or unsupported macOS version”, 2025-03-11), 18385, 18386, 18222, and 11668. Those issue bodies were not opened. Pull request 22592’s timeline says it was referenced by an issue titled “Error: unknown or unsupported macOS version: :dunno” numbered 152, and by a pull request “brew-src: 5.1.14 -> 6.0.1” numbered 154. Those numbers are outside the Homebrew/brew issue sequence around 22607, and those two links were not opened. — [Pull request 22592](https://github.com/Homebrew/brew/pull/22592)

### Inferences

- On 2026-06-08 and 2026-06-09 the supported fix recorded by a maintainer was pull request 22592. From 2026-06-11 that fix is an installed Homebrew at tag `6.0.0` or any later stable tag. By 2026-10-19 that includes `7.0.10`, which also treats Golden Gate as a supported release rather than a prerelease.
- The `PATH` `sw_vers` comment is a user workaround, and the absolute path in `brew.sh` means it does not change `HOMEBREW_MACOS_VERSION` on the tags that were opened. Resetting the brew git checkout to the development branch on 2026-06-10 would pick up merge `e7ef812`, which is consistent with asptweets reporting success the day before the stable tag.

### Gaps

- No macOS 26 beta issue or pull request was opened, so this note does not describe a documented macOS 26 `:dunno` workaround.
- Issue 19462 and the number-152 / number-154 references on the pull request timeline were not opened. Their repository was not confirmed.
- `brew developer on` was not traced in source. The only record here is falchion10’s comment. It was not a maintainer instruction in the thread that was read.
