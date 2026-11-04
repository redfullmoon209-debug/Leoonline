# LEOM: product identity & multi-platform targets

**Public game name: LEOM.** This replaces the previously used LEOONLINE branding.
Unity Cloud project: https://cloud.unity.com/organizations/18968508051495/projects/8ff585f7-c6f7-4736-a844-1db884381c30
Unity source root: `unity/`
Unity game code/art root: `unity/Assets/LEOM/`

## Repository versus product identity
- The GitHub repository remains `redfullmoon209-debug/Leoonline` for now to protect the existing Godot build, GitHub Actions and Pages URL. That repository name is **legacy infrastructure**, not the public name of the new game.
- Existing Godot project files at the repository root have not been renamed or deleted. They are source material and a backup.
- LEOM's WebGL preview initially uses the legacy stable hosting path `/Leoonline/unity/` until hosting/repo migration is explicitly scheduled.
- Do not rename or archive the separate Unity Cloud COV project; it is not LEOM.
- Before shipping, finalize the studio/company legal name, `com.<publisher>.leom` identifiers, trademark review, application icons and store text.

## Targets from the same Unity project
| Target | Deliverable | Controls | Release condition |
| --- | --- | --- | --- |
| Browser WebGL | Unity Web build on static hosting | Mouse/keyboard + touch-responsive UI | Build and real-device browser QA |
| Google Play Android | AAB | Touch joystick + actions, landscape | Android signing, Play Console, app review |
| Apple App Store iOS | IPA/TestFlight via macOS/Xcode Cloud | Touch joystick + actions, safe-area | Apple Developer, certificates, provisioning, App Store review |

The local offline prototype is not multiplayer. WebGL is a **client**, not the persistent MMORPG server. Authoritative game state and online account data require separate network services. Browser build should not write files using raw .NET APIs where persistent web saves are expected: use platform-compatible persistence and validate.

## Name-change invariants
- All new player-facing title, debug HUD, Product Name and future store metadata: **LEOM**.
- Preserve original source asset IDs and data for later migration; do not replace them merely to match branding.
- Avoid renaming package/bundle IDs after first publication; the IDs cannot safely be changed without creating a new app listing.
- Build profiles and packages must be prepared for Web, Android and iOS independently; no claim of published builds before CI and store verification.
