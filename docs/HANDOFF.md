# Local consolidation handoff

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

- The requested Focus audio alert and 0-100 health-percentage slider are **not
  implemented**. Health restrictions must be resolved before implementing a sound
  trigger. The reviewed native combat-audio path announces party numbers at
  ten-percentage-point thresholds; no supported replacement with the Focus sound
  was found. The requested in-game health-readability diagnostic has no reported
  result. Do not treat this request as completed or silently substitute native
  announcements for it.
- `scripts/check-wow-api-export.ps1` currently fails because the installed Forever
  build differs from the reviewed 1.60.1.69913 export. Refresh and review a matching
  export before further API work. Do not merely change metadata to silence it.
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

This consolidation saves intended source locally, without a release or a new
installation. Prior task installations have separate timestamped backups under
the user's Codex backups/ApogeeHeals directory. SavedVariables must be preserved;
schema version 3 includes bindings and learned buffs. A runtime rollback to an
older schema is not permission to overwrite current saved data.

The historical external task record is
`C:/Users/nickm/.codex/visualizations/2026/09/20/01a0c0d9-631c-7892-9f22-242436baae8a/apogee-heals-click-bindings-plan.md`.
It contains installation backup paths and the evolution of user decisions;
later entries supersede earlier plans. This repository handoff preserves the
remaining work so old conversations can be archived without losing it.
