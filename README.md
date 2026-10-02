# Apogee Heals

Minimal five-player healing frames for **WoW Forever 1.60.x, interface 16001**.
Prototype 0.1.0-dev; reviewed against local export 1.60.1.70170. The owner confirmed incoming heals and reviewed
the appearance in game; full live acceptance remains pending. Not released. Classic Era is deliberately unsupported.

## Prototype

- **Threat demo (solo preview; ends in combat)** in Heals settings previews the
  same threat rows without a group or live threat reads. It shows strong/weak
  leads, loss of lead/aggro, unknown/no-comparison states, mana-type rails, mob HP and the
  target outline. One sample bar loses and rebuilds threat over a 24-second loop.
  The DEMO label and footer identify fictional data; its thresholds are visual
  examples, not gameplay rules. Drag the header to review placement. Uncheck the
  demo to restore the live meter's saved enabled state. Combat, zoning, reload
  and Defaults end the demo. The demo toggle is not saved.

- Optional **Threat checks (freeze after combat; until reload)** in Heals settings
  opens a movable diagnostic panel independently of the tank threat stack.
  Enable it before combat and select a living enemy. Seven fields show separate
  Lua-read and native-display-call PASS/FAIL checks. Any failure stays latched for
  that fight, with the first Lua failure reason. Periods with no target or a
  friendly/dead target are skipped. Results freeze after combat for screenshots; the next fight
  starts fresh. `--` means no sample. Display PASS means the native call accepted
  the value, not proof of rendering or correct percentage semantics. Only public
  check outcomes are retained for this session; no threat samples are saved.
  Coverage lines count API attempts (including periodic polls), skipped checks,
  elapsed combat time, first/last sample times and the longest gap without a
  sample. These also freeze after combat. Solo tests do not establish group access.

- Independent eight-row tank threat stack, disabled by default. Seven stable mob
  slots and one reserved selected-target slot follow normal Tab targeting with
  a yellow outline; duplicate target presentation is suppressed natively.
  Drag its header outside combat. Toggle **Tank threat stack** in Heals settings.
  The reserved target row appears only during combat; idle selection adds no row.
- Compact threat frames use the reference style: level/name over a large threat
  area, a thin mob-HP strip below, and a left rail that is blue for confirmed
  mana users and gray otherwise (including unknown mana capability). The gold
  outline identifies your selected target. Repeated warning/aggro/percentage text
  and raid markers are removed from these compact rows.
- Threat fill starts at the center: native relative percentage minus 100 drives
  the right half when positive and the left half when negative. Equal-to-reference
  leaves only the center tick. Each half caps at 100 percentage points. The native
  selector is unchanged: percentage-of-lead when tanking, raw percentage otherwise.
  This is a prototype reference, not a guaranteed aggro-loss threshold; grouped
  percentage semantics still need validation.
- Green/yellow/orange/red fill retains native lead/aggro warning colors. LOST
  marks confirmed loss of aggro. `?` means unavailable/restricted data; `-` means
  a tank lead reading of zero provides no usable comparison. Restricted percentages
  never enter arithmetic: they clear both halves instead. Health still passes
  directly to native display sinks. Diagnostics remain available for access checks.
- Coverage depends on exposed hostile nameplates plus the selected target.
  Overflow shows an exact extra count when identities permit, otherwise a tracked
  count. No bar predicts time until aggro loss or guarantees a reaction window.

See [class support](docs/CLASS_SUPPORT.md) for the buff/cleanse matrix, yellow
guidance, native weapon displays, limitations and live acceptance checks.

- Player-first vertical stack followed by party1 through party4. Player remains
  while solo; native visibility hides missing units and all rows in raids.
- Up to eight native debuff icons extend right of each player/party health bar,
  after the reserved drinking-icon space. Hover for the native aura tooltip.
  All harmful aura types qualify, including effects you cannot dispel. Native
  code owns ordering, updates and combat display; the icons themselves do not cast.
- Target sits above the player with a full-row gap; target's target stays
  closely above target. Both retain their size and align with the stack's left
  edge. The drag handle sits above the pair; no helper caption is shown.
- While the selected target casts, its power strip temporarily shows amber cast
  progress without adding height. Casts fill forward and channels drain backward;
  normal power returns when casting stops. Health and names remain visible.
- Default placement aligns beneath Apogee Tank's Forever bars, with a 9px gap
  below its single-target layout. No Tank dependency or frame attachment is used.
  Existing saved positions remain unchanged; use **Reset positions** to adopt it.
- Apogee Tank styling with taller health bars: 112x14 health, 112x5 power, at 2x scale.
  Full character names use Blizzard's native class colors, left-aligned inside health bars with the
  original game font at the same smaller size as NPC names and dark shadow, including
  during combat. Restricted names stay blank. Long names truncate. Health-state and active-resource colors remain.
  A muted level appears immediately to the left of each name; unavailable levels
  show a question mark. Names and levels remain visible in combat; status messages
  still replace them for dead, offline or out-of-range units.
- A fine opaque rule divides health from power. A slim Blizzard class-color strip sits flush inside each row's left
  edge, spanning health and power with a dark separator. It remains visible in combat.
  Fully transparent spaces separate
  players, with no outer border or header lane. OFFLINE and DEAD
  replace the name inside the empty health bar. A small cup beside the health bar
  indicates confirmed drinking outside combat, with smaller artwork in a dark inset frame.
  Its countdown shows seconds remaining on the current drink aura when the client
  supplies its duration. Stopping early clears the icon and timer.
  The number is centered on the cup without a seconds suffix.
- Red rage and yellow energy fills use softer tones; the preview handle is shorter
  with smaller, muted lettering. Native class-name colors remain unchanged.
- Incoming heals from all healers appear as a pale-green segment immediately
  after current health. Forever's native calculator caps it at missing health
  and accounts for healing absorption. No numbers or extra settings are added.
- Native left-click targeting when unassigned, with healing click bindings on Left, Right,
  Middle, Mouse 4 and Mouse 5 (plain, Shift and Ctrl). No global binding overrides.
  Standard native target actions also retain the client's spell/item cursor behavior.
- Escape -> Options -> AddOns -> Apogee Heals: Reset positions, Buff reminders
  and Factory reset. Position and healing assignments are saved
  per character.

### Healing bindings

Left-click the **healing icon outside the minimap's lower edge** to open or close
healing bindings. Its border turns gold while the editor is open. Right-click
opens Heals settings. **Right-drag** moves it around the outside rim for this
session only; reload/login resets it to the upper-left of the Apogee cluster,
followed by Keybinds in the middle and Tank below-right. Historical saved angles
are retained but ignored. The orbit
is circular, with radius half the larger minimap dimension plus 16 pixels,
including resized or rectangular maps. It updates on map resize and UI scale
changes. The button locks during combat.
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

## Paladin cleansing buttons

Learned Purify and Cleanse have permanent buttons to the right of each player/party
health bar, followed by the drinking indicator and the debuff strip. Left-click
casts that spell on the row's player, including in combat. Modified clicks do
nothing. Unlearned spells are hidden; other classes do not get these buttons.

A separate native gold halo appears for matching harmful-aura types: poison and
disease for Purify, plus magic for Cleanse. Both can glow for poison/disease.
The glow indicates a matching type, not guaranteed success, range or mana.
Idle cleansing icons are gray at 30% opacity. A matching native indicator adds
the full-color spell image and gold edge without changing the button's action.
The game chooses the effects removed; clicking a button never selects one debuff.
Buttons stay visible with no debuffs. Native icons themselves remain display-only.
Buff reminders on the left and right-side icons are square and span the combined health and power bar height,
aligned at both edges, with a narrow gap between icons.

The earlier rejected AuraButton/secure-action composition remains unused. These
are independent, permanently configured secure buttons and native visual siblings.
Native clicks, glow layering and combat behavior require in-game acceptance.

## Healing Mouse placement

Healing Mouse opens directly below Keybinds' default Mouse grid, aligned on the
left with a small gap. It also works independently with Keybinds absent or hidden.
Dragging the header saves a per-character position; updates preserve it.

In **Options > AddOns > Apogee Heals**, **Reset positions** restores the party/target
bars, Healing Mouse and minimap button without changing assignments or reminders.
**Factory reset** asks for confirmation, then clears this character's
Heals assignments, reminders and positions and restores available class defaults.
Other characters, other addons and WoW keybindings are unchanged. Both controls
are locked during combat; confirming an already-open dialog in combat does nothing.

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

Reset positions and Factory reset are grouped last in Settings, in that order,
with matching button dimensions and spacing across Heals and Keybinds.

Healing Mouse assignments also apply to the target and target-of-target bars,
including learned class defaults, plain/Shift/Ctrl mouse clicks and bandages.
Each click uses that bar's recipient; native game restrictions decide whether
its spell or item can be used. Changes to assignments remain locked in combat.


### Unified Defaults

Defaults clears this character's healing assignments, buff preferences and positions. Use the top-right Defaults button and confirm; changes are blocked in combat.
