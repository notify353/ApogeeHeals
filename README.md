## Shared launcher candidate

Requires matching Apogee UI shared support from the complete distribution.
Left-click the green button to toggle available editors together: open all if
any is closed, otherwise close all. Right-click for direct component settings
and Reset minimap position; right-drag to save its position per character.
Editors can still be closed independently through their existing controls.
DEV/PROD and clients keep separate state. Component Defaults does not reset the
launcher. New support folder requires a full game restart after installation.
Forever remains source-only until matching fresh client validation.

## Simple health-bar range (October 20, 2026)

The applied, unmodified left-click spell alone controls health-bar fading.
Confirmed out of range fades health artwork and its text/incoming-heal children
to 45%; in-range or unknown stays fully opaque. Buff buttons are sibling frames
and retain their own exact-spell range checks without inheriting this fade.
An empty left slot or bandage uses guarded 40-yard proximity (inclusive), keeping
non-caster group distance useful. A spell's unknown range never falls back to
proximity. Right-click and modifier bindings do not alter this cue. The Near/Far
and per-click labels are removed. Power and support icons retain normal opacity.
No casting or recipient changes. Native appearance/combat acceptance pending.

# Apogee Heals

Buff buttons on party and target rows now explicitly cast only on that row's
recipient, using the selected rank without an alternate self target. Player-row
buffs, auras and aspects keep their intentional self-cast behavior. Native
range/line-of-sight acceptance of this buff extension is pending.

Settings appear under **Apogee** (or **Apogee DEV**) with a one-word child label. Only enabled, loaded addons with settings appear; changes to enabled addons take effect after reload.

Minimal five-player healing frames for **WoW Forever 1.60.x, interface 16001**.
Prototype 0.1.0-dev; reviewed against local export 1.60.1.70450. The owner confirmed incoming heals and reviewed
the appearance in game; full live acceptance remains pending. Not released. Classic Era is deliberately unsupported.

## Prototype

- Select another friendly player to show a compact Follow, Inspect and Talents
  group inside the right end of the target health bar. Three role-sized icons brighten on hover; tooltips name each action.
  The target name reserves space for the icons. It disappears in combat, while moving frames and while loading.
  Party rows have no action buttons; buffs never reposition the strip.
  All three appear together only when Follow and inspection range/availability checks pass.
  Movement refreshes the group; clicks still recheck the current target.

- Talents opens the native inspected talent window after matching data arrives.
  Target changes, combat, roster changes, zoning and a five-second timeout cancel
  pending inspection. No automatic follow, retargeting or stored talent data.

- **Threat demo (solo preview; ends in combat)** previews scripted threat bars
  and warrior debuff icons without live reads. The checkbox is session-only;
  combat, zoning, reload and Defaults end the demo. Uncheck it to restore the
  live meter's saved enabled state. Its animation is illustrative, not a prediction.

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

- Optional **Tank threat stack** tracks up to eight exposed enemy nameplates in
  stable rows. Selecting an enemy adds a gold marker outside its existing bar;
  selection never creates or moves a row. Additional enemies wait for a free slot.
- The compact group is fixed horizontally at screen center, with the first row
  centered vertically and subsequent rows below it. There are no names, levels,
  health strips, headings or status words. Blue backgrounds identify confirmed
  mana users; other rows use charcoal.
- Threat fill begins at the center. The chosen display reference is 100%, with
  each half spanning 100 percentage points. Tanking uses percentage-of-lead and
  only extends right; zero or values below the reference stay centered. Otherwise,
  raw percentage can extend left or right. Restricted values use native display
  sinks without Lua arithmetic. Warning colors retain the game's lead/aggro states.
  This scale is not a verified aggro-loss threshold or time-to-loss prediction.
- Warrior debuffs appear in fixed order: Sunder Armor, Thunder Clap, Demoralizing
  Shout. Native player-only aura containers control icon visibility and stacks.
  Unconfirmed effects leave no placeholder; absence of an icon is not proof of
  missing data versus a missing effect. Sunder counts are centered white text;
  native formatting leaves a single application unnumbered. Other class spell
  sets have not been implemented.
- The owner confirmed the installed live layout and debuffs work. This does not
  establish exact grouped threat-percentage semantics or every class/client case.

See [class support](docs/CLASS_SUPPORT.md) for the buff/cleanse matrix, yellow
guidance, native weapon displays, limitations and live acceptance checks.

- Player-first vertical stack followed by party1 through party4. Player remains
  while solo; native visibility hides missing units and all rows in raids.
- A small gold crown at the right of the party leader's health bar updates when
  leadership changes outside combat. Names reserve space for it. Solo and
  unavailable leader data show no crown; the layout preview crowns its first row.
- Native tank, healer and damage icons appear just right of the crown for the
  game's assigned role on each player/party row. Unassigned or unavailable roles
  stay blank. Both role and leader icons hide immediately in combat and refresh
  from current assignments afterward; class is never used to guess a role.
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
- Only your own druid player row splits the existing power strip equally in cat/bear form:
  blue mana above energy/rage. Caster form restores the full mana strip.
- Apogee Tank styling with taller health bars: 112x14 health, 112x5 power, at 2x scale.
  Full character names use Blizzard's native class colors, left-aligned inside health bars with the
  original game font at the same smaller size as NPC names and dark shadow, including
  during combat. Restricted names stay blank. Long names truncate. Health-state and active-resource colors remain.
  A muted level appears immediately to the left of each name; unavailable levels
  show a question mark. Names and levels remain visible in combat; status messages
  still replace them for dead or offline units. Range never hides identity.
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
- Escape -> Options -> AddOns -> Apogee Heals: Reset positions, Smart buffs
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

With default spells enabled, empty plain Left uses Priest **Lesser Heal**,
Paladin **Holy Light**, Druid **Healing Touch** or Shaman **Healing Wave**.
Right-click and modifier slots have no automatic defaults.
Each uses its highest learned rank. Defaults are
class-specific and do not write saved assignments.
Your manual spell always takes priority, even if it becomes unavailable. Removing
the override restores the default. The default icon has no remove control; drop a
spell or bandage onto it to override. Other classes have no healing default.

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
Spell bindings use an explicit recipient with no alternate target and clear any
remaining targeting cursor. Clicking your own row explicitly targets you.
Range and line-of-sight failure behavior still needs native acceptance.
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

## Smart buffs

Open **Options > AddOns > Apogee > Heals > Smart buffs** (Apogee DEV for DEV).
Supported buffs appear as soon as you learn them; no discovery cast is needed.
Each buff family has a per-character preference that survives reloads and rank upgrades:

- **Smart:** show useful missing buffs beside their recipient. A yellow border
  identifies a suggested next choice; hover for its reason and native spell tooltip.
- **Manual:** show only when you click the recipient's class strip to expand choices.
- **Off:** hide the family, including in expanded choices.

Left-click an icon to cast on that row's player without selecting them. Modified
clicks do nothing. Native range, mana, reagents and spell restrictions still apply.
Buff choices and their settings close/hide in combat and resume afterward. Self
buffs appear only on your own row. No automatic casts occur.

Paladins have one **Blessings** preference. All learned lasting blessing choices
remain available, with conservative role/class guidance and the highest learned
rank of each ordinary or Greater variant. Any recognized existing blessing
suppresses automatic blessing choices. Expansion lets you select another type;
it does not offer to replace the same type from another caster. **Auras (self)**
controls the separate own-aura choices. Old Might/Wisdom checklist values do not
control these choices and are retained only for compatibility.

Priests maintain Fortitude and Spirit independently: Fortitude serves every
recipient, Spirit is suggested for healers/mana classes, Inner Fire is self-only,
and Shadow Protection defaults to Manual. Druids get Mark for everyone and Thorns
for assigned tanks; expansion offers Thorns for other recipients too. Mages get
Intellect for healers/mana classes and a separate Armor choices group. Warlock
armor alternatives also share a group. Other supported self buffs and Hunter
aspects use the same Smart/Manual/Off controls. Classes without supported spells
show an empty state rather than unrelated spell choices.

Recognized ranks and group versions satisfy their family, including another
caster's buffs. Independent families stay independent. Own buffs can reappear
with a remaining-time label below two minutes; another caster's or unknown-source
buff is preserved until it disappears. Unreadable observations never mean missing.
Group versions such as Prayers/Gift/Brilliance count as coverage but are not new
casting actions; Greater Paladin blessings retain their existing explicit actions.

Existing disabled catalog/discovered buffs remain Off unless you choose a new
mode. For grouped armor choices, any legacy disabled variant keeps the group Off.
Additional five-minute upkeep buffs can still be learned from your successful
casts followed by a complete readable own-aura observation within ten seconds.
Their entries use the same controls, and opt-outs survive relearning and rank
changes. Short effects, passive spells, items and pet casts are not learned.
Battle Shout remains handled by Keybinds. See [class support](docs/CLASS_SUPPORT.md).

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

The applied, unmodified left-click spell alone controls health-bar fading.
Confirmed out of range fades health artwork and its text/incoming-heal children
to 45%; in-range or unknown stays fully opaque. Buff buttons are sibling frames
and retain their own exact-spell range checks without inheriting this fade.
An empty left slot or bandage uses guarded 40-yard proximity (inclusive), keeping
non-caster group distance useful. A spell's unknown range never falls back to
proximity. Right-click and modifier bindings do not alter this cue. The Near/Far
and per-click labels are removed. Power and support icons retain normal opacity.
No casting or recipient changes. Native appearance/combat acceptance pending.

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

Target buff suggestions appear only for living friendly player characters out of
combat. NPCs, pets, hostile players and unknown target identity are excluded.

Click the class-color strip on a player, party or friendly-player target bar to
show learned buff options in the existing icon row on the left, even if buffs
are already active. Click an icon to recast or change the buff. Click the strip
again to return to normal missing-buff reminders. Expansion works outside combat
only and resets on combat entry or target/group changes. No extra panel opens.

Buff icons also appear when a buff has less than two minutes remaining. A small
m:ss timer on the icon counts down once per second below two minutes; longer
durations use compact minute/hour labels. Refreshing the buff hides
the reminder again. Missing buffs have no timer; permanent or unreadable durations
are never guessed. Expanded options show known remaining times as well.

Buffs applied by someone else (or with unknown caster identity) remain covered
until they disappear. Their matching recast choices are hidden to avoid replacing
a stronger or talent-improved buff. Other blessing types remain available through
the strip. Early refresh reminders apply to your own confirmed applications.

Automatic spell assignments are off initially, including existing characters.
Use **Apogee > Keybinds > Enable default spells** to switch built-in Keybinds and Heals
spells on or off for this character. Custom assignments keep their locations
and always take priority. Changes are unavailable during combat.
