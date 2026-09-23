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
- `./build-debug.sh` builds, `./test.sh` builds with warnings-as-errors and runs
  tests, `./lint.sh` runs swiftlint and periphery (dead-code detection).
