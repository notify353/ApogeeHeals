# Changelog

## Unreleased

- Show the existing healing icon in the native AddOns list using TOC metadata.
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
