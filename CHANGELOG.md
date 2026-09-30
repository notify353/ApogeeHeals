## Unreleased

- Hide the reserved threat target row outside combat, removing the idle selection
  UNKNOWN placeholder while keeping stable encounter rows independent.
- Preserve independent lead warnings when detailed threat is unavailable. Display
  restricted native warning risk, threat amount and aggro through native sinks;
  clear stale values on failure/removal. Solo and dungeon live retests remain pending.
- Add a movable eight-row tank threat stack with stable mob slots, normal-target
  highlighting, explicit native lead/aggro warnings and conservative unknown states.
  Keep continuous centered bars disabled pending proof; live dungeon acceptance
  is separate from mock/source checks and central DEV installation.
- Refresh the Forever API baseline to 1.60.1.70124 and review threat/nameplate sinks.

- Add one confirmed top-right Defaults button combining settings and position resets.

# Changelog

## Unreleased

- Display restricted target and target-of-target names through native text sinks
  instead of blanking them in instances; use the same safe path for party names.

- Remove Battle Shout from pre-group buff suggestions, including saved generic reminders.

- Match all side icons to settings-tile size and spacing, center them vertically,
  and contain gold borders inside the tiles so stacked rows stay separated.

- Add researched class upkeep, friendly Priest/Shaman/Druid/Mage cleansing,
  Hunter own-aspect choices, and native player weapon enchantment displays.
  Preserve Paladin controls and document pet/group/item interaction limits.

- Add buff choices, recommendations, cleansing and native debuffs to the friendly selected target.

- Highlight a role-first, class-fallback blessing suggestion in yellow, with a tooltip explanation.

- Limit blessing choices to lasting party buffs; exclude Protection, Freedom and Sacrifice.

- Offer all learned blessing variants on each unblessed player/party row, with matching left-side geometry.

- Offer learned Paladin auras beside the player buff reminders when their own aura is off, outside combat.

- Detect eating as well as drinking and show the active aura native tooltip on hover.

- Center the drinking countdown without a seconds suffix, dim idle cleansing
  buttons, and match left-side buff reminder size and spacing to the right side.

- Show native seconds remaining on the drinking cup without changing its position.

- Align right-side icons with the full health-plus-power height using square
  artwork and consistent spacing; keep cleansing glows within the row gaps.

- Add permanent learned Purify/Cleanse buttons beside Paladin player/party bars,
  with independent native gold glows for matching debuff types and fixed-unit clicks.

- Display up to eight native harmful-aura icons to the right of player/party
  health bars, with native tooltips and space for the drinking indicator.

- Remove the target-of-target helper caption and its reserved drag-handle space.

- Correct Forever surname display by joining the separate name and surname
  returns, matching the client's Camelot name formatter with public-value guards.

- Show native cast/channel progress in the selected target's existing power
  strip, restoring power when casting stops without increasing frame height.

- Display full readable player names, including surnames and hyphens.

- Use the smaller NPC name font size consistently for player, party, target,
  target's target and preview names, including after changing target type.
- Keep readable player/party names and levels visible during combat. Preserve
  restricted-value handling and dead/offline/out-of-range status presentation.

- Move target and target's target above the player/party stack, left-aligned
  with a full-row gap, increased after the first in-game spacing review. Keep both bar sizes and the saved party position;
  reserve space for the drag handle at the screen's top edge.

- Match Essentials with a near-opaque dark settings background behind controls,
  preserving behavior and saved settings.

- Allow bag bandages on Healing Mouse tiles, with saved item identity, icons,
  drag/swap/remove and native secure use on the clicked party member.

- Bring minimap button centers onto the shared nominal tangent orbit: half the
  larger minimap dimension plus 16 pixels, with equal 46-pixel-minimum chord gaps.
  Preserve native border padding and artwork; painted rim alignment needs live review.

- Reset the minimap icon to the upper-left of the default cluster on
  reload/login. Right-drag applies for the current session only, including across
  resize/zoning; historical saved angles are retained but ignored.

- Default Healing Mouse to the right edge of the optional same-family Keybinds
  Weapons header with aligned tops and an eight-pixel gap. Preserve manual placement per
  character; use centered standalone placement when the anchor is unavailable.

- Fade each row and show OUT OF RANGE only when the exact applied unmodified
  left-click spell reports a public out-of-range result for that fixed recipient.
  Unknown/private results clear feedback; range-only sampling preserves combat actions.

- Disable the rejected Purify native-button composition after the live client
  reported forbidden OnClick replacement warnings. Preserve existing buff layout
  and report the feature unavailable; poison-triggered combat Purify remains blocked.
- Correct minimap dragging to a smooth circular orbit using half the larger map
  dimension plus 16 pixels; preserve the current session angle on resize.
- Place the minimap button outside the rim at the upper-left cluster default; right-drag changes only the current session. Preserve artwork and
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

## Defaults update

- Provide one confirmed top-right Defaults control; consolidate reset controls and preserve combat safeguards.
