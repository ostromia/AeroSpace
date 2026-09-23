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
