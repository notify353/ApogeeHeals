# Apogee Heals

Minimal five-player healing frames for **WoW Forever 1.60.x, interface 16001**.
Prototype 0.1.0-dev; reviewed against local export 1.60.1.69913. The owner confirmed incoming heals and reviewed
the appearance in game; full live acceptance remains pending. Not released. Classic Era is deliberately unsupported.

## Prototype

- Player-first vertical stack followed by party1 through party4. Player remains
  while solo; native visibility hides missing units and all rows in raids.
- Apogee Tank styling with taller health bars: 112x14 health, 112x5 power, at 2x scale.
  Names use Blizzard's native class colors, left-aligned inside health bars with the
  original readable game font and dark shadow, shown only outside
  combat. Long names truncate. Health-state and active-resource colors remain.
  A muted level appears immediately to the left of each name; unavailable levels
  show a question mark. Levels hide together with names in combat and status states.
- A fine opaque rule divides health from power; fully transparent spaces separate
  players, with no outer border or header lane. OFFLINE and DEAD
  replace the name inside the empty health bar. A small cup beside the health bar
  indicates confirmed drinking outside combat, with smaller artwork in a dark inset frame.
- Red rage and yellow energy fills use softer tones; the preview handle is shorter
  with smaller, muted lettering. Native class-name colors remain unchanged.
- Incoming heals from all healers appear as a pale-green segment immediately
  after current health. Forever's native calculator caps it at missing health
  and accounts for healing absorption. No numbers or extra settings are added.
- Native left-click targeting, with no click-casting configuration or registration.
  Standard native target actions also retain the client's spell/item cursor behavior.
- Escape -> Options -> AddOns -> Apogee Heals: Unlock frames and Reset position.
  Unlock also shows a five-member sample party, even while solo, with health,
  power, drinking and incoming-heal examples. Preview rows cannot target anyone.
  Each unlock starts at full health and power for three seconds, then smoothly
  cycles through damage, resource use, incoming heals and recovery back to full.
  It also demonstrates an out-of-range Rogue, an offline Druid and a dead Priest.
  Out-of-range fading is a preview example only; live range detection remains deferred.
  The twelve-second loop stops immediately when locked or combat begins.
  Drag the handle above the stack. Releasing the drag locks it; combat also locks it.
  Locking ends the preview and restores the live party display.
  Only the position is saved per character. Reload starts locked.

The addon leaves Blizzard frames and other Apogee addons alone. It does not need
Tank, Keybinds or Party Health Bars installed. No raid/pet frames, shield/HoT overlays,
dispel indicators, live range fading, health/power numbers, profiles, minimap button
or drinking countdowns.

## Drinking limitations

The original addon supplies a small set of candidate Classic drink identities.
Only IDs resolved by Forever's own spell API enter the recognition list, along
with their localized names. Helpful auras must be readable and match one of
these identities. Unknown, restricted, failed or incomplete scans show no icon;
absence of an icon does not prove the member is not drinking.

The local export validates the API, not server aura data. Actual Forever drinks
and localized equivalents still require live testing. There are no mana-based
guesses, thirsty warnings, countdowns, alerts or messages.

## Architecture

`ApogeeHeals.lua` composes private addon modules. Core owns client access,
native display sinks and position storage. PartyFrames owns rendering, secure
unit buttons and event lifecycle; Drinking owns recognition; UI owns fixed
style and the two settings controls. Only an event-triggered one-shot timer is
used for live refreshes; OnUpdate handlers run only during dragging or the visible
animated preview (drawing capped at twenty times per second).

IncomingHeals owns a native calculator and clipped preview bar per health frame.
Prediction events refresh through the same coalesced event loop. Unavailable
prediction APIs or reads clear the preview while ordinary frames keep working.
No incoming-heal estimate is computed in Lua or saved. The owner confirmed predictions visible in game;
combat, cancellation and multi-healer cases still require live acceptance.

Protected buttons are created outside combat with immutable unit tokens.
Native visibility drivers own their show/hide behavior. Dragging moves an
independent handle; the protected anchor follows only outside combat. Combat
stops the handle immediately and saves the last safe position after combat.
No custom restricted snippets or global WoW API replacements are used.

`ApogeeHealsDB` contains version 1 and position x/y offsets in scaled UI units
relative to screen center. Invalid or off-screen positions recover safely.
A newer schema is preserved untouched and disables startup with an explanation.

## Development

Run `pwsh ./scripts/test-local.ps1` for Lua 5.1 parsing, TOC checks, mocked
scenarios and whitespace checks. Run `pwsh ./scripts/check-wow-api-export.ps1`
before API changes; it checks the installed build and export file freshness.
See docs/API_REFERENCE.md for matching-source authority and optional native
contract tests. Mocked engine behavior does not establish live combat safety.

No installation or deployment is performed by these scripts. After explicit
installation approval, the destination folder is Interface/AddOns/ApogeeHeals
in the Forever test client. Do not overwrite an existing installation blindly.
Follow docs/ACCEPTANCE.md before calling this prototype playable or releasing it.

MIT licensed. Tank style/access/display patterns and the original Party Health
Bars drink identity list are adapted from notify353's MIT-licensed addons;
the original copyright notice is retained in LICENSE.
