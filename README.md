# BrewMenu (brew dater)

A tiny macOS menubar app that watches Homebrew for updates and alerts you without listing every outdated package. Click it to upgrade.

- Menubar mug icon: white/template when up to date, **red** when Homebrew (or any package it manages) has updates, orange if a check fails.
- Menu shows a one-line status ("Up to date" / "N updates available") — never a package list.
- **Upgrade Now** opens your default terminal app and runs `brew update && brew upgrade`.
- **Check Now** re-checks immediately. Otherwise it checks automatically every 6 hours.
- No Apple Developer account involved — the app is ad-hoc signed for local use only. This is intentional: the $99/year Apple Developer Program fee is not something this project will ever require, so there's no notarization and no Mac App Store distribution. That's why Gatekeeper needs the right-click → Open dance on first launch (see below).

## Install

```
./scripts/bundle.sh
cp -R .build/BrewMenu.app /Applications/
```

Then open `/Applications/BrewMenu.app` (first launch: right-click → Open, since it's ad-hoc signed rather than notarized, and Gatekeeper will otherwise refuse to open it).

### Run automatically at login

System Settings → General → Login Items → add `BrewMenu.app`.

## Rebuilding after code changes

```
./scripts/bundle.sh
```

Rebuilds the release binary, reassembles `.build/BrewMenu.app`, and re-signs it. Re-copy to `/Applications` (or just relaunch from `.build/` while developing).

## Development

- `swift build` — compile.
- `swift run BrewMenuApp` — run unbundled, straight from the build dir (still shows in the menubar since it sets its own accessory activation policy).
- `swift run BrewCoreVerify` — runs the `BrewCore` behavior checks. This project uses a hand-rolled assert-based checker instead of XCTest/Swift Testing, because neither test framework ships with Xcode Command Line Tools alone (both live inside Xcode.app, which isn't installed here). Behaviors covered: up-to-date detection, outdated-package counting, `brew update` running before `brew outdated`, failure handling, and the upgrade script's contents.

### Manually forcing a status (no need to wait on real brew state)

```
BREWMENU_FAKE_STATUS=up open .build/BrewMenu.app        # or: swift run BrewMenuApp
BREWMENU_FAKE_STATUS=updates open .build/BrewMenu.app
BREWMENU_FAKE_STATUS=fail open .build/BrewMenu.app
```

This only fakes the status shown in the menu — clicking **Upgrade Now** always runs the real `brew update && brew upgrade` regardless of this variable.

## How it finds `brew`

Checks `/opt/homebrew/bin/brew` (Apple Silicon) then `/usr/local/bin/brew` (Intel), using whichever exists.

## Uninstall

Quit the app, remove it from Login Items if added, then delete `/Applications/BrewMenu.app`.
