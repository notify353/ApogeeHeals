# Changelog

## Unreleased

- Add a Purify candidate for Paladins with the spell learned: native poison-only
  aura slots own indicator/button visibility; fixed-unit secure clicks are
  configured outside combat. Native aura-button/secure-input composition still
  requires live acceptance before claiming working combat cleansing.
- Correct minimap dragging to a smooth circular orbit using half the larger map
  dimension plus 20 pixels; preserve default and user-dragged angles.
- Place the minimap button outside the rim at the shared Heals default of 260
  degrees; right-drag to persist an angle per character. Preserve artwork and
  clicks, suppress clicks after dragging, and adapt to map resize/UI scaling.
- Paladins get learned Might reminders without discovery; learned Wisdom is
  available unchecked in Buff reminders. Preserve opt-outs and prior blessing
  priority, upgrade seeded ranks, and show at most one missing blessing per unit.
- Buff reminder hover uses Blizzard's native tooltip for the exact spell/rank;
  clear it when the reminder changes, hides, changes roster or enters combat.
- Show the shared green Apogee brand icon in the native AddOns list using a
  bundled copy of the existing artwork and addon-local TOC metadata.
- Avoid unchanged buff-action/visibility setup, hidden picker rebuilds and
  repeated per-recipient spell/scope lookups. Suspend queued refreshes while
  leaving the world; keep fresh aura observations and combat-safe updates.
- Reviewed Forever 1.60.1.70009 export and refreshed the build-warning baseline.
  Confirmed existing notify353 metadata, independent feature-folder organization
  and Forever-only startup. Retained client-validated inherited spell identities;
  current-build live acceptance remains pending.
- Reject inaccessible API table contents before indexing spell/aura data;
  require the native table-access guard at startup. Missing optional spell APIs
  leave saved actions inactive and recover safely when available again.
- Initial standalone Forever-only five-player frames with native left-click
  targeting, raid hiding and per-character positioning.
- Tank-inspired health/power bars at 2x scale, taller health fills, an opaque
  health/power rule, transparent player spacing and no outer border.
- Readable left-aligned class-colored names with muted levels, hidden in combat;
  dead/offline states clear resources and replace names.
- Confirmed readable drinking auras display a compact framed icon outside combat.
- Native incoming-heal segments from all healers, capped at missing health,
  without addon-side calculations on restricted values.
- Two native settings: Unlock frames and Reset position. Unlock shows a full-party
  animated demo starting at full health/power and returning to full after damage,
  healing, resource use, drinking, offline, dead and simulated out-of-range states.
- Lua, TOC, whitespace, mocked behavior and matching-export contract validation.
  Healing click bindings and clickable buff reminders are implemented. Full live
  acceptance remains pending; live range detection remains deferred.
