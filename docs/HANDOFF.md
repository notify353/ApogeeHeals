# Local consolidation handoff

## Owner acceptance and GitHub handoff (2026-09-24)

The owner reports testing all five installed addons in game and authorized
integration/commit/push of the current Heals candidate to canonical main and its
existing GitHub remote. This is user-reported in-game acceptance, not exhaustive
checklist evidence or a live FPS measurement. The 21 installed package files
still match the fully tested performance candidate; no runtime changed for this
handoff. Focus audio remains separate unfinished work. Rollback assets and
worktrees are retained; no release/tag is requested.

## Implemented work

The original Forever prototype is extended with a compact healing mouse editor,
minimap shortcut, fifteen independent click combinations, and secure fixed-unit
casting. Manual ranks take priority over class defaults: Priest Lesser Heal on
Left and Power Word: Shield on Right; Paladin Holy Light on Left.

Upkeep reminders learn successfully cast, readable friendly buffs lasting at
least five minutes, across classes without a buff catalog. Each learned reminder
can be disabled. Native self-buff classification determines party coverage;
missing icons can be clicked outside combat to reapply the learned spell.

Heals remains independent of Tank and Keybinds. Default/reset placement sits
below Tank's single-target Forever layout, existing positions are preserved,
labels show first names, and each row has a flush Blizzard class-color strip.
Classic Era support is not requested.

## Pending work and validation

- The refreshed **1.60.1.70009** export passes strict verification. The table
  contents-access defect and missing optional spell-namespace error paths are
  fixed with regressions. The full suite passes, including current exported
  native click/visibility functions with mocked engine inputs. See
  `docs/QUALITY_REVIEW.md`; this is not current-build in-game acceptance.
- The requested Focus audio alert and 0-100 health-percentage slider are **not
  implemented**. Health restrictions must be resolved before implementing a sound
  trigger. The reviewed native combat-audio path announces party numbers at
  ten-percentage-point thresholds; no supported replacement with the Focus sound
  was found. The requested in-game health-readability diagnostic has no reported
  result. Do not treat this request as completed or silently substitute native
  announcements for it.
- The 2026-09-24 cleanup reviewed the fresh 1.60.1.70009 export and updated the
  metadata and runtime warning baseline. The export checker passes; see
  `docs/API_REFERENCE.md` for retained inherited behavior and review scope.
  A later patch still requires a matching export review before API work.
- The complete local Lua 5.1 suite passes against the available export. Mocks and
  source-contract tests do not establish current-client secure execution or
  visual acceptance. Follow `docs/ACCEPTANCE.md`, especially all mouse modifiers,
  invalid recipients, combat transitions and coexistence with Keybinds.
- User feedback confirmed buff learning and clickable reapplication in game.
  Complete live acceptance of defaults, automatic party coverage, layout, labels,
  class strips and the current client build remains pending.
- A manual self-only setting was rejected. Flask/consumable reminders were
  discussed but deferred; they are not implemented.

## Preservation and resuming

The cleanup and review fixes were installed locally on 2026-09-24 under the
owner's standing authorization; no release or publication occurred. Prior task installations have separate timestamped backups under
the user's Codex backups/ApogeeHeals directory. SavedVariables must be preserved;
schema version 3 includes bindings and learned buffs. A runtime rollback to an
older schema is not permission to overwrite current saved data.

The historical external task record is
`C:/Users/nickm/.codex/visualizations/2026/09/20/01a0c0d9-631c-7892-9f22-242436baae8a/apogee-heals-click-bindings-plan.md`.
It contains installation backup paths and the evolution of user decisions;
later entries supersede earlier plans. This repository handoff preserves the
remaining work so old conversations can be archived without losing it.

## Verified local installation (2026-09-24)

- Latest update: performance/lifecycle fixes installed at 15:27 local time.
  Backup: `C:/Users/nickm/.codex/backups/ApogeeHeals/performance-20260924-152750`.
  It includes `previous/`, SHA-256 `manifest.json` and `ROLLBACK.txt`. All 21
  copied files match the validated source. Prior installed files matched the
  earlier installation manifest; no unknown files or user modifications found.
  See `docs/PERFORMANCE_REVIEW.md` for measured call counts and regressions.
- The following source/destination remain current; the earlier cleanup backup
  below is retained as an additional rollback point.
- Source: `C:/Users/nickm/.codex/worktrees/356e/ApogeeHeals`, branch
  `codex/forever-cleanup`, including uncommitted cleanup and review fixes.
- Destination: `C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/ApogeeHeals`.
  Verified as a real directory without nested links; existing package files
  matched the previous repository version. No unexpected edits or files found.
- Backup: `C:/Users/nickm/.codex/backups/ApogeeHeals/forever-cleanup-20260924-152038`.
  `previous/` contains all replaced files; `manifest.json` records previous and
  installed SHA-256 hashes; `ROLLBACK.txt` describes restoring those same paths.
- Copied and SHA-256 verified all 21 package files: TOC, its 18 Lua references,
  README and MIT license. Strict current 70009 export verification passed;
  the complete native-source/mock suite passed before installation.
- SavedVariables, other addons and the game executable were untouched. The game
  was not operated or restarted. Reload the UI (or launch the client if closed)
  to load the new files. Installation is not in-game acceptance.
- Future requested addon changes include checked, rollback-capable local Forever
  installation without a separate prompt. Publication remains separately authorized.
