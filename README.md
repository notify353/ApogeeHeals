# Apogee Heals

Minimal five-player healing frames for **WoW Forever 1.60.x, interface 16001**.
Prototype 0.1.0-dev; reviewed against local export 1.60.1.70009. The owner confirmed incoming heals and reviewed
the appearance in game; full live acceptance remains pending. Not released. Classic Era is deliberately unsupported.

## Prototype

- Player-first vertical stack followed by party1 through party4. Player remains
  while solo; native visibility hides missing units and all rows in raids.
- Default placement aligns beneath Apogee Tank's Forever bars, with a 9px gap
  below its single-target layout. No Tank dependency or frame attachment is used.
  Existing saved positions remain unchanged; use **Reset position** to adopt it.
- Apogee Tank styling with taller health bars: 112x14 health, 112x5 power, at 2x scale.
  First names only use Blizzard's native class colors, left-aligned inside health bars with the
  original readable game font and dark shadow, shown only outside
  combat. Restricted names stay blank. Long names truncate. Health-state and active-resource colors remain.
  A muted level appears immediately to the left of each name; unavailable levels
  show a question mark. Levels hide together with names in combat and status states.
- A fine opaque rule divides health from power. A slim Blizzard class-color strip sits flush inside each row's left
  edge, spanning health and power with a dark separator. It remains visible in combat.
  Fully transparent spaces separate
  players, with no outer border or header lane. OFFLINE and DEAD
  replace the name inside the empty health bar. A small cup beside the health bar
  indicates confirmed drinking outside combat, with smaller artwork in a dark inset frame.
- Red rage and yellow energy fills use softer tones; the preview handle is shorter
  with smaller, muted lettering. Native class-name colors remain unchanged.
- Incoming heals from all healers appear as a pale-green segment immediately
  after current health. Forever's native calculator caps it at missing health
  and accounts for healing absorption. No numbers or extra settings are added.
- Native left-click targeting when unassigned, with healing click bindings on Left, Right,
  Middle, Mouse 4 and Mouse 5 (plain, Shift and Ctrl). No global binding overrides.
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
  Position and healing assignments are saved per character. Reload starts locked.

### Healing bindings

Left-click the **healing icon outside the minimap's lower edge** to open or close
healing bindings. Its border turns gold while the editor is open. Right-click
opens Heals settings. **Right-drag** moves it around the outside rim for this
session only; reload/login resets it to the upper-left of the Apogee cluster,
followed by Keybinds in the middle and Tank below-right. Historical saved angles
are retained but ignored. The orbit
is circular, with radius half the larger minimap dimension plus 16 pixels,
including resized or rectangular maps. It updates on map resize and UI scale
changes. The button locks during combat. The existing
**Options > AddOns > Apogee Heals > Edit healing bindings** shortcut also works.
Drop a learned
friendly spell from the player spellbook onto one of fifteen mouse/modifier slots.
Pickup followed by clicking a slot also works. The selected spell ID/rank is kept;
hover to see its name and rank. Active helpful spells (including friendly buffs)
are accepted; harmful and passive spells are rejected. New manual assignments start empty.

Priests automatically get **Lesser Heal on plain Left** and **Power Word: Shield
on plain Right**. Paladins get **Holy Light on plain Left**.
Each uses its highest learned rank. Defaults are
class-specific and do not write saved assignments.
Your manual spell always takes priority, even if it becomes unavailable. Removing
the override restores the default. The default icon has no remove control; drop a
spell onto it to override. Other classes and combinations have no defaults yet.

Drag a tile onto another to move or swap; dropping outside cancels. Use its small
x to remove it. Escape or the minimap button closes the editor. Drag the header to move it
for this session. The editor is unprotected and never casts. Combat closes it and
cancels editing. Preview party rows also never cast.

The editor follows Keybinds' floating-grid design: 36-pixel tiles, four-pixel gaps,
inset icons and a narrow translucent header, with no dialog backdrop. Columns
are Left, Right, Middle, Mouse 4 and Mouse 5, labeled L/R/M/4/5. S- and C- prefixes
identify Shift and Ctrl rows; hover a tile for its full combination, or the header
for editing instructions. Invalid drops explain the issue in chat.

Click a live party row with the assigned combination to cast on that fixed unit.
Plain left-click targets when it has neither an assignment nor a learned class
default. Removing an assignment restores its class default, or targeting when
none is available. Empty Shift/Ctrl slots do nothing,
including on Left. An unavailable assigned spell stays inactive, without targeting
instead. Alt and combined modifiers have no healing
action. Removed or unavailable spells are inactive; unavailable assignments stay
saved and recover when learned again. Spellbook changes during combat apply after
combat. Native WoW enforces spell range, recipient validity and resource costs.

These are local unit-button actions, not global keyboard/mouse overrides or edits
to Blizzard's click-binding configuration. **Mouse 3-5 coexistence with Apogee
Keybinds remains pending live testing**, since Keybinds claims those inputs globally.
Combat routing, target preservation, invalid-recipient behavior and visual layout
also require live acceptance. Test installations do not establish live acceptance.

The addon leaves Blizzard frames and other Apogee addons alone. It does not need
Tank, Keybinds or Party Health Bars installed. No raid/pet frames, shield/HoT overlays,
dispel coverage, health/power numbers, profiles
or drinking countdowns.

## Learned upkeep buffs

Paladins receive **Blessing of Might reminders as soon as a rank is learned**;
no discovery cast is needed. Learned **Blessing of Wisdom** is also added to
Buff reminders, initially unchecked. To prefer Wisdom, uncheck Might and check
Wisdom there. These defaults use the highest client-confirmed learned ordinary
rank and preserve saved opt-outs through upgrades and reloads. They do not seed
greater blessings, seals, short defensive cooldowns or combat utility.

Only one maintained blessing is prompted per recipient: the first enabled,
learned blessing in the existing watch order. Earlier discovered choices retain
priority over appended defaults; there is no automatic class/role optimization.
Any recognized ordinary or greater Might, Wisdom, Kings, Salvation, Sanctuary or
Light already on a recipient suppresses another blessing prompt, even from a
different caster. This conservative policy avoids replacement prompts; it does
not optimize multi-Paladin blessing assignments. Other discovered upkeep buffs
remain independent. A full 32-entry watch list is preserved without eviction.

Hover a visible reminder for **Blizzard's native spell tooltip**, including its
actual rank. Tooltips close when reminders change/disappear, the roster changes
or combat begins. Click behavior is unchanged.

Heals learns active, friendly player spells after a successful cast and a complete,
readable aura observation within ten seconds. The aura must come from you and
have a duration of at least five minutes. Discovery has no class filter or spell list.
Short buffs, passive spells, items, pets, failed casts and unreadable observations
do not teach a reminder. Cast buffs outside combat to teach them.

Missing buffs appear as small icons to the left of each living, connected party
row, with four visible icons and an overflow count. The client's self-buff check
keeps self-only effects on your row; party-capable buffs are checked on every
row even when first learned on yourself. If classification is unavailable, actual
party application remains the fallback evidence. Existing learned buffs use this
rule without relearning. **Left-click a reminder icon to reapply its learned spell
to that row's player**, without selecting them first. Modified clicks do nothing.
The game still enforces range, mana, reagents and spell restrictions. Reminders
hide in combat and during preview; no automatic casts occur. Learning scope
avoids assuming that self-only buffs can be applied to everyone.
Dead, offline, unknown and preview rows receive no reminders.
Learning and reminders pause in combat and resume from fresh observations afterward.

An existing buff from another caster satisfies coverage. Observed ranks with
the same localized client spell name share one watch entry. Differently named
single/group buffs are not guessed to be equivalent. The five-minute rule is a
duration filter, not a claim that every qualifying spell should always be maintained.

Open **Options > AddOns > Apogee Heals > Buff reminders** to uncheck an unwanted
reminder. Choices persist across reloads and relearning. The list supports up to
32 learned entries. Self-only versus party coverage is detected automatically;
there is no manual scope setting. No duration countdown, automatic casting, party chat alerts
or shared Tank state is involved. Tank can be absent or disabled.

## Purify (blocked by live native restriction)

The live 70009 client rejected the poison-triggered secure-button candidate with
five `Cannot assign script handler for 'onclick' (cannot replace a forbidden
script handler)` warnings from SecureTemplates.xml:8. The candidate is disabled:
Heals no longer constructs its native aura containers, buttons or hit areas.
Reload after installing the correction to remove the previously created frames.
Existing buff reminders, spell tooltips and minimap behavior remain available.

Poison-triggered, fixed-unit Purify during combat remains unfulfilled. Native
poison display works independently, but its intrinsic click handler cannot be
replaced by the secure spell-action handler. No indicator-only, permanent-button
or invisible-hitbox substitute has been enabled. A different visible-action
design requires explicit agreement; settings report the unavailable feature.

## Healing Mouse placement

With Keybinds available, Healing Mouse opens eight logical pixels to the right of its Weapons
header with aligned tops. The optional anchor follows the Weapons position even
when its configuration panel is hidden; opening Heals does not show Keybinds.
Without that anchor, Healing Mouse opens centered. Dragging its header overrides
the default and saves a separate per-character editor position. Existing party
frame placement is unchanged. DEV only uses the DEV Keybinds anchor.

## Spell range

Rows fade and show OUT OF RANGE when the exact unmodified left-click spell
reports that recipient out of range, including the learned class default.
Checks use each row's fixed unit, independent of the selected target. They update
about five times a second without scanning auras. Missing, restricted or invalid
results restore normal presentation without claiming the spell is in range.
No mapping means no spell-range feedback. Combat keeps the actually installed
mapping until deferred binding changes can apply safely. Native combat behavior
still needs live confirmation.

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

The addon identity remains `ApogeeHeals`, its display title is **Apogee Heals**,
and its author is **notify353**. Feature folders contain PascalCase Lua modules;
`docs`, `scripts` and `tests` hold supporting material. These conventions match
the independent Apogee addons without introducing a shared runtime or dependency.

`ApogeeHeals.lua` composes private addon modules. Core owns client access,
native display sinks and character storage. PartyFrames owns rendering, secure
unit buttons and event lifecycle; Drinking owns recognition; Bindings owns spell
validation and secure click assignments; UI owns style, settings and the binding
editor. Buffs owns class-independent discovery, missing-buff icons and the watch
list. Only an event-triggered one-shot timer is
used for live refreshes; OnUpdate handlers run during active spell-range sampling, dragging or the visible
animated preview (drawing capped at twenty times per second).

Unchanged buff reminders retain their secure setup; watched spell scope is
resolved once per refresh and hidden pickers refresh on reopening. Bindings
resolve once per combination for all fixed recipients. Pending refreshes pause
between leaving and entering the world. Aura observations remain fresh;
offline work-count measurements are in `docs/PERFORMANCE_REVIEW.md`.

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

`ApogeeHealsDB` contains version 3, a learned upkeep-buff watch list,
a mouse-combination-to-spell-ID binding map,
and position x/y offsets in scaled UI units
relative to screen center. Invalid or off-screen positions recover safely.
A newer schema is preserved untouched and disables startup with an explanation.

## Development

Run `pwsh ./scripts/test-local.ps1` for Lua 5.1 parsing, TOC checks, mocked
scenarios and whitespace checks. Run `pwsh ./scripts/check-wow-api-export.ps1`
before API changes; it checks the installed build and export file freshness.
See docs/API_REFERENCE.md for matching-source authority and optional native
contract tests. Mocked engine behavior does not establish live combat safety.

After a central build, run `lua tests/generated_dev.lua <ApogeeHealsDev-root>`
against its generated child folder for buff discovery/defaults/tooltips and
minimap placement/dragging under
the real DEV identity. The harness mocks admission as granted; central checks
separately own admission, pin hashes and distribution isolation.

No installation or deployment is performed by these scripts. Requested addon
changes include local installation after checks into Interface/AddOns/ApogeeHeals
in the verified Forever beta client, with a rollback backup and copy verification.
Preserve unexpected user edits and saved data; publication requires separate approval.
Follow docs/ACCEPTANCE.md before calling this prototype playable or releasing it.

MIT licensed. Tank style/access/display patterns and the original Party Health
Bars drink identity list are adapted from notify353's MIT-licensed addons;
the original copyright notice is retained in LICENSE.
