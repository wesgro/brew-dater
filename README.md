# BrewMenu (brew dater)

Hark! A most diminutive macOS menubar app — one that keepeth watch upon thy Homebrew, and doth alert thee unto updates, yet never burdeneth thine eyes with a tedious listing of every last outdated package. Click upon it, and lo — the upgrade commenceth.

- The menubar mug icon — plain and white 'tis, whilst all is well; but turneth **red**, verily, when Homebrew — or any package under its dominion — hath grown stale; and orange doth it turn, should a check go awry.
- The menu revealeth but a single line of status ("Up to date" / "N updates available") — never, upon mine honour, a full accounting of packages.
- **Upgrade Now** — click it, and thy default terminal shall spring open, running `brew update && brew upgrade` upon thy command.
- **Check Now** compelleth an immediate reckoning. Absent thy intervention, the app taketh it upon itself to check anew every six hours.
- No Apple Developer account hath been sought, nor shall it e'er be — the app is signed ad-hoc, for thine own local use alone. This is by design, and not by any oversight — the $99-per-annum tribute demanded by the Apple Developer Programme is a toll this project shall never pay, not now, not ever. Hence there be no notarization, and no passage unto the Mac App Store. And 'tis for this very reason that Gatekeeper requireth the right-click-and-Open ritual upon first launch (a rite described more fully below).

## Installation — a Guide for the Willing

```
./scripts/bundle.sh
cp -R .build/BrewMenu.app /Applications/
```

Then openeth thou `/Applications/BrewMenu.app` — but heed this well: upon the first launch, thou must right-click and choose Open, for the app is ad-hoc signed rather than notarized, and Gatekeeper — ever suspicious — shall otherwise bar the gate against it.

### That It Might Launch Automatically, Upon Thy Login

System Settings → General → Login Items — add thou `BrewMenu.app` thereunto.

## Rebuilding — Should Thy Code Be Altered

```
./scripts/bundle.sh
```

This doth rebuild the release binary, reassemble `.build/BrewMenu.app` anew, and re-sign it besides. Copy it once more unto `/Applications` — or simply relaunch it straight from `.build/`, whilst thou art yet tinkering.

## For the Developer — Ye Who Wouldst Tinker Further

- `swift build` — to compile, plainly.
- `swift run BrewMenuApp` — run it unbundled, straight from the build directory — it shall still appear within the menubar, for it setteth its own accessory activation policy, unaided.
- `swift run BrewCoreVerify` — runneth the `BrewCore` behavioural checks. Know thou this: the project employeth a hand-rolled, assert-based checker in place of XCTest or Swift Testing — for neither framework travelleth with the Command Line Tools alone; both dwell within Xcode.app proper, which is not installed upon this machine. The behaviours thus proven are: the detecting of up-to-dateness, the counting of outdated packages, the running of `brew update` before `brew outdated` (and not after, mind thee), the handling of failure, and the contents of the upgrade script itself.

### Compelling a False Status, Manually — That Thou Need Not Await Homebrew's True State

```
BREWMENU_FAKE_STATUS=up open .build/BrewMenu.app        # or: swift run BrewMenuApp
BREWMENU_FAKE_STATUS=updates open .build/BrewMenu.app
BREWMENU_FAKE_STATUS=fail open .build/BrewMenu.app
```

Mark thee well — this trickery affecteth only the status displayed upon the menu. Should thou click **Upgrade Now**, the true and real `brew update && brew upgrade` shall run regardless — this variable holdeth no sway over it.

## Whence It Findeth `brew`

It seeketh first at `/opt/homebrew/bin/brew` (the path of Apple Silicon), and failing that, at `/usr/local/bin/brew` (the path of Intel) — whichsoever existeth, that one it shall use.

## Uninstallation — Should Thou Tire of It

Quit thou the app — remove it from thy Login Items, if placed there it was — and delete, at the last, `/Applications/BrewMenu.app`.
