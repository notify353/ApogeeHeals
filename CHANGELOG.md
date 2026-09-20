# Changelog

## Unreleased

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
  Full live acceptance remains pending; click-to-cast and live range are deferred.
