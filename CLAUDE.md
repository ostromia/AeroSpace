# CLAUDE.md

Personal fork of [nikitabobko/AeroSpace](https://github.com/nikitabobko/AeroSpace).
The only intended deviation from upstream is the menu bar tweaks below. Everything
else must stay byte-identical to upstream so rebases stay cheap.

## Where the menu bar UI lives

`Sources/AppBundle/ui/` holds all menu bar code:

- `MenuBar.swift` — the dropdown shown when clicking the icon (`MenuBarExtra` content).
- `MenuBarLabel.swift` — the icon/text rendered in the menu bar itself.
- `TrayMenuModel.swift` — `@Published` state the dropdown binds to.

Everything else in that folder (`VolumeView`, `NSPanelHud`, `MessageView`,
`SecureInputView`, `AppearanceTheme`, `ExperimentalUISettings`) is unrelated to the
dropdown.

## Fork tweaks

Re-apply these after every upstream sync. Both are deletions; upstream reintroduces
them in `MenuBar.swift`, so that file is the expected rebase conflict.

### 1. No version label / "Copy to clipboard" button

Delete from the top of the `MenuBarExtra` block in `MenuBar.swift`:

- the `shortIdentification` and `identification` `let` bindings,
- `Text(shortIdentification)`,
- `Button("Copy to clipboard") { identification.copyToClipboard() }` and its
  `.keyboardShortcut("C", modifiers: .command)`,
- the `Divider()` immediately after (otherwise the menu opens with a stray separator).

Also delete the `extension String { func copyToClipboard() }` from
`Sources/AppBundle/util/appBundleUtil.swift` — the button is its only caller and the
repo runs periphery dead-code detection.

Keep `gitHash` / `gitShortHash` in `Sources/Common/gitHashGenerated.swift`: generated
build metadata, used elsewhere.

### 2. No sponsorship section

Delete from `MenuBar.swift` the `Button` opening
`https://github.com/sponsors/nikitabobko` — its `Text("Sponsor AeroSpace on GitHub")`
label, the `Text(viewModel.sponsorshipMessage)` subtitle, and the `Divider()`
immediately after.

Then delete:

- `@Published var sponsorshipMessage` from `TrayMenuModel.swift`,
- `Sources/Common/model/sponsorshipPrompts.swift` (whole file; only held the rotating
  prompt strings).

Verify nothing is left: `grep -rni sponsor Sources/` must return no hits.

### 3. No "Open config in ..." button

Delete the `openConfigButton()` call from the `MenuBarExtra` block in `MenuBar.swift`
— the entry labelled `Open config in '<editor>'`, bound to ⌘,. It sits between
`getExperimentalUISettingsMenu(...)` and `reloadConfigButton(...)`.

This one is a single-line deletion. Do **not** delete the `openConfigButton(
showShortcutGroup:)` function itself, nor `getTextEditorToOpenConfig()` or
`shortcutGroup(...)`: `MessageView.swift` still calls them for the config-error popup,
which is a separate window and is deliberately left alone.

Verify: `grep -rn openConfigButton Sources/` must show exactly two hits — the
definition in `MenuBar.swift` and the call in `MessageView.swift`.

### 4. No "Experimental UI Settings" submenu, style fixed to system font

Delete the `getExperimentalUISettingsMenu(viewModel: viewModel)` call from the
`MenuBarExtra` block in `MenuBar.swift`.

Then rewrite `Sources/AppBundle/ui/ExperimentalUISettings.swift` down to just the
type and the enum, because removing the submenu orphans everything else and periphery
runs with `--strict`:

- delete `getExperimentalUISettingsMenu(...)` and the `MenuBarStyleButton` view,
- replace the UserDefaults-backed `displayStyle` with `var displayStyle: MenuBarStyle
  { .systemText }` — the picker is gone, so nothing can write the stored value, and
  system font is the style this fork wants,
- delete the `ExperimentalUISettingsItems` enum (only the UserDefaults key),
- strip `MenuBarStyle` down to `enum MenuBarStyle: String` with its five cases,
  dropping `CaseIterable`, `Identifiable`, `Equatable`, `Hashable`, `id` and `title`,
  which only the submenu used. Equatable/Hashable stay synthesised automatically for a
  raw-value enum, and `MenuBarLabel.swift` still switches over all five cases.

Keep `MenuBarLabel`'s `style:` / `color:` init parameters. They are only passed as nil
now, but the properties are read in `menuBarContent`, so they are not dead.

To restore the picker, revert this file — upstream's version is self-contained.

### 5. No "Workspaces:" header

Delete the `Text("Workspaces:")` line directly above the `ForEach(viewModel.workspaces,
...)` in `MenuBar.swift`. One line, nothing else changes: keep the `ForEach`, and keep
the `Divider()` after it that separates the workspace list from Enable/Disable.

`MenuBarLabel.swift` is not involved — it renders the menu bar icon, not the dropdown.

## Syncing with upstream

Do not squash history. Shared ancestry with upstream is what keeps conflicts confined
to the few lines this fork actually changes; squashing removes the merge base and makes
every future pull conflict across the whole tree.

```
git fetch upstream && git rebase upstream/main
```

`git log --oneline upstream/main..HEAD` shows this fork's full delta.

## Repo conventions

- `.gitignore` ignores the repo root by default (`/*`). A new top-level file needs an
  explicit `!/name` entry, or `git add -f`.
- Swift package builds from directory globs — deleting a source file needs no build
  file edit.
- `./lint.sh` runs swiftlint (`only_rules`, `strict: true`) and periphery
  (`scan --strict`), so unused declarations are build failures — but see below, it
  cannot currently run on this machine.
- The entry-point scripts are documented in `dev-docs/development.md`. Which of them
  actually work here is covered in the next section.

## Building and installing (this machine)

**Toolchain constraint.** `.swift-version` pins Swift 6.4. The installed Xcode ships
Swift 6.2.3, and swift.org has no 6.4 release yet, so swiftly is deliberately *not*
installed (`swiftly install` fails on a missing download URL; `script/setup.sh` then
falls back to plain `swift` and prints a harmless warning).

`Sources/AppBundleTests/tree/TreeNodeTest.swift` uses `weak let`, a Swift 6.4 feature,
so **anything that compiles the test target fails**: `./test.sh`, `./lint.sh`,
`./build-debug.sh` and `./run-debug.sh` — the latter two call `swift build
--build-tests`, and no argument suppresses it. This is upstream code, unrelated to the
fork tweaks. The practical consequence: periphery cannot be run locally, so the
dead-code reasoning in the tweaks above has to be done by hand. Revisit when Swift 6.4
ships in Xcode.

Also note `xcode/project.yml` sets `SWIFT_VERSION: 6.2`, so the *app* target builds
fine on 6.2.3. Only the tests need 6.4.

**Debug run** (skips the test target, so it works):

```
swift build --product AeroSpaceApp && ./.build/debug/AeroSpaceApp
```

Quit the installed AeroSpace first — two instances fight over window management and the
server socket. Ctrl-C to stop.

**Release build and install.** Do not use `./build-release.sh` or
`./install-from-sources.sh`. They also build man pages (Ruby/bundler/asciidoctor),
shell completions (Rust/cargo, fish), universal binaries, a zip and two Homebrew casks;
they abort on any uncommitted file; and `install-from-sources.sh` additionally installs
`brew-install-path` from a third-party tap and is labelled work-in-progress upstream.
For just the app bundle:

```
./generate.sh --ignore-cmd-help
( cd xcode && xcodebuild -scheme AeroSpace -configuration Release \
    -destination "generic/platform=macOS" -derivedDataPath .xcode-build clean build )
pkill -x AeroSpace
rm -rf /Applications/AeroSpace.app
ditto xcode/.xcode-build/Build/Products/Release/AeroSpace.app /Applications/AeroSpace.app
```

`generate.sh` regenerates `xcode/AeroSpace.xcodeproj` (xcodegen is downloaded into
`.deps/` automatically) and rewrites `versionGenerated.swift` and
`gitHashGenerated.swift` to `SNAPSHOT` placeholders — that shows up in `git status` and
is harmless, since tweak 1 deleted the UI that displayed them. Use `ditto`, not
`cp -R`: it preserves the code signature, and copying over an existing bundle leaves
stale files inside it.

The Homebrew cask was uninstalled, so brew no longer owns `/Applications/AeroSpace.app`.

**Codesigning drives the Accessibility permission.** `generate.sh` writes
`CODE_SIGN_IDENTITY: aerospace-codesign-certificate` into the Xcode project. Appending
`CODE_SIGN_IDENTITY="-"` to the xcodebuild line signs ad-hoc, which needs no
certificate but makes the designated requirement a bare cdhash — so macOS treats every
rebuild as a different app and revokes Accessibility permission each time. A
self-signed **Code Signing** certificate of exactly that name (Keychain Access →
Certificate Assistant → Create a Certificate → Self-Signed Root) makes the requirement
`certificate leaf[subject.CN] = "aerospace-codesign-certificate"`, which survives
rebuilds.

- `security find-identity -v -p codesigning` — the certificate must be listed. "0 valid
  identities found" means Certificate Type was not set to `Code Signing`.
- `codesign -d -r- <app>` — verify before installing: expect `certificate leaf[...]`,
  not `cdhash`.
- Switching between ad-hoc and certificate changes the identity once more, so the
  stale entry in System Settings → Privacy & Security → Accessibility should be removed
  with `−` and re-added.

**The `aerospace` CLI is a separate product** that the .app does not contain, and
nothing else provides it now that the cask is gone. Karabiner-Elements invokes
`/opt/homebrew/bin/aerospace` by absolute path (it runs commands with a minimal PATH),
so after every app rebuild:

```
swift build -c release --product aerospace
cp .build/release/aerospace /opt/homebrew/bin/aerospace
```

The CLI and the app refuse to talk across mismatched versions, so always build both
from the same tree.

## Working agreements

- **Never run `git` commands in this repo.** The user runs git themselves. Propose
  commit messages and commands for them to run; do not execute them, and never stage,
  commit, delete or rewrite anything through git.
- The user's shell aliases `ls` to a script that ignores its arguments and lists `$PWD`.
  Use `/bin/ls`, `find`, or the Glob tool when a path matters.
