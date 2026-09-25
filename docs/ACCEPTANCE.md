# In-game prototype acceptance

On 2026-09-24 the owner reported testing all five installed Apogee candidates
in game and authorized committing/integrating/pushing them to main. This records
user-reported acceptance of the installed Heals cleanup, quality and performance
candidate on the reviewed 1.60.1.70009 client. It is not an exhaustive execution
record for every case below, a measured FPS result, or completion of the separate
Focus audio request. Earlier pending entries remain detailed regression checklists.

## Learned upkeep buffs (pending)

- Paladin defaults/tooltips: on a fresh DEV Paladin with Might learned, verify
  an unbuffed self and party member show Might without a discovery cast. Learning
  Wisdom must leave Might selected and add Wisdom unchecked in Buff reminders.
  Existing enabled/discovered blessings keep their earlier priority. Uncheck
  Might/check Wisdom to switch. Rank upgrades/reloads preserve explicit opt-outs.
  An existing ordinary/greater maintained blessing suppresses other blessing
  prompts, including another caster's blessing; at most one appears per unit.
  Verify this conservative policy rather than multi-Paladin assignment logic.
- Hover self/party reminders: native spell description and actual rank should
  match the click action. Leave, hide, roster replacement, coverage, rank change,
  preview, zoning and combat must clear stale tooltips. No protected action
  changes or hidden hit areas may be introduced by tooltip handlers. These
  new defaults and tooltip behavior have offline tests; live acceptance is pending.

- Reminder learning and click-to-reapply were reported working by the owner.
  Full acceptance remains pending: left-click each missing icon on self and party1-party4 and verify the
  correct learned spell, exactly one cast, and unchanged selected target with
  both key-down preferences. Modified clicks must do nothing. Range, resource,
  reagent and recipient failures must not redirect to another player. Test
  combat transitions and preview mode for hidden/inactive reminder hit areas.

- With Tank disabled or absent, cast a known five-minute-or-longer friendly buff
  outside combat on yourself and a party member. Confirm automatic discovery,
  icon removal where present and missing icons on other living party members.
  Confirm learning a party-capable buff on yourself produces a missing reminder
  on an unbuffed party member immediately, including after loading an older
  self-scoped watch entry. Truly self-only effects must stay on your own row.
- Test another class without any spell catalog changes. Short effects such as
  Renew/shields, passive effects, items, pets and failed casts must not be learned.
  Cast/aura IDs that differ cannot be inferred; record actual live identities
  if an otherwise qualifying buff is not discovered.
- A different caster's same-name/rank buff satisfies coverage. Removal/expiry
  restores the icon. Learning a rank with the same client name keeps one entry.
  Differently named group and single buffs are separate; disable unwanted watches.
- Uncheck a learned entry in Buff reminders, recast and reload: it stays disabled.
  Recheck it, test scrolling and four-icon overflow, and inspect row spacing.
- Combat immediately clears icons and closes the picker, with no blocked actions.
  Combat exit refreshes real state. Unknown aura data, dead/offline/missing units,
  preview mode, zoning and raid conversion must not leave stale reminders.
- Existing bindings and position survive schema migration. Tank's files and
  saved data remain untouched. Source/mock checks do not establish live behavior.

## Purify (live failure; requested feature unresolved)

- The 70009 live candidate failed with five forbidden OnClick replacement
  warnings from SecureTemplates.xml:8. Do not repeat that rejected composition.
- After corrective DEV installation, reload outside combat and confirm those
  warnings no longer appear; no Purify icon or hit target is created. Confirm
  existing Might reminders/tooltips and circular minimap behavior still work.
- Offline regression checks establish zero attempted construction and preserved
  buff layout, not live correction acceptance. The requested poison-triggered,
  fixed-unit combat cast remains blocked. An alternative visible-action design
  needs explicit agreement; release acceptance remains held.

## Healing Mouse placement (live acceptance pending)

- With Keybinds configuration visible, open Healing Mouse: its header must touch
  the Weapons header's right edge with aligned tops and no horizontal gap.
- Move Weapons and confirm the default dock follows. Hide Keybinds configuration
  and confirm Heals remains usable. With Keybinds absent, confirm centered fallback.
- Drag Healing Mouse, close/reopen/reload, and confirm custom placement survives
  without moving party frames or Weapons. Check UI scaling and combat closure.
- DEV must bind only the DEV header; no cross-family UI access. Screen clamping
  can prevent a flush fit when the combined panels would extend off screen.

## Left-click range (live acceptance pending)

- Assign two learned friendly spells with different ranges in turn to plain Left.
  Move a party recipient across each spell boundary, keeping a different current
  target. Only out-of-range rows should fade to 45% and show OUT OF RANGE.
- Confirm player and party1-party4 recipients, learned class default/removal,
  exact manual ranks, combat movement and deferred spellbook changes. Clicks
  must still cast the configured spell at the fixed recipient without retargeting.
- Confirm dead/offline/missing rows and invalid/unavailable range reads do not
  retain an old OUT OF RANGE claim. Preview and zoning stop live range sampling.
  Mocks cannot establish native protected-frame or restricted-result acceptance.

## Existing frame acceptance

- Minimap placement/dragging (new, live acceptance pending): verify the 260-degree
  default sits outside the minimap beside Tank/Keybinds without overlap; check
  round/resized/rectangular maps and UI scaling. Drag through axes, diagonals and
  intermediate angles: the orbit must stay circular with constant radius, never
  trace a square. Right-drag and reload to
  retain placement. Left-click still toggles bindings; ordinary right-click still
  opens Heals settings. Drag release must not open settings, and the next fresh
  click must work. Combat, zoning and hiding cancel dragging without losing the
  saved angle or leaving update callbacks. Invalid map geometry defers placement.

The owner approved test installation and confirmed incoming heals visible in game.
Visual iterations were reviewed during testing; the complete checklist below remains
pending. Requested addon changes include verified local installation. Local mocks and export checks
do not complete any of these checks.

- Login and reload outside combat: player row appears, locked, with correct name,
  health and active resource. Repeat a reload during combat; construction waits
  until combat ends without blocked actions.
- Add/remove each party member, including during combat. Verify names and fills
  follow native unit tokens; click every displayed row and confirm the target.
- Check unassigned plain left-click targeting with ActionButtonUseKeyDown enabled and disabled.
  Unassigned right/middle/extra buttons must not cast.
- Convert to raid and leave raid: all rows hide in raid and recover afterward.
- Damage/heal, spend/regain mana, and test rage/energy/resource-form changes.
  Dead/offline states clear fills; resurrection/reconnection restore them.
- Cast a heal on self and a party member, then cancel it: preview appears after
  current health and clears on cancellation/landing. Test a second healer at the
  same time, overhealing, full health, damage during a cast and healing absorption.
  Verify the pale-green segment stays inside the health bar, including at zero
  health and under restricted combat values, and leaves click-to-target working.
- Test ordinary drink ranks and available special drinks on player and party
  members. Confirm icon removal on cancellation, death, disconnect and combat.
  Record actual spell IDs if an expected drink is not recognized; do not infer
  support solely from a resolved spell name.
- Compare beside Tank and Keybinds at the same game UI scale over light/dark
  scenery. Check 2x proportions, health colors, power colors, name truncation,
  status fit, empty backgrounds and target hit areas.
- Confirm levels and names are left-aligned inside health bars and stay legible above incoming
  heals. Names must disappear immediately on combat entry and return on exit,
  with no change to health/power bar dimensions or click targeting.
- Inspect the stack: a fine opaque health/power rule, fully transparent spaces
  between players, no outer border,
  and a small drinking cup on the right. DEAD/OFFLINE must replace names cleanly.
- Unlock, drag and release: new position persists through reload, starting locked.
  While unlocked and solo, verify all five sample rows are visible, clearly labeled
  Preview above the stack, aligned with the live layout, and cannot target units.
  Confirm the demo begins full for three seconds, cycles through damage, healing,
  resource use, drinking, offline, dead and simulated range states, then resets all
  rows to full. Unlocking again must restart clean. Range is preview-only.
  Verify locking restores the real roster immediately and combat ends the preview.
  Enter combat during a drag: handle stops/hides with no blocked action; movement
  remains locked afterward. Verify reset and changed resolution/UI scale recovery.
- Keep Blizzard frames visible and verify no sibling-addon settings change.
- Observe script errors and blocked-action/taint reports throughout. Resolve any
  failures before describing this build as live-accepted or publishing it.

## Healing click bindings (pending)

- Verify the bottom-right minimap healing icon remains separate from Keybinds.
  Left-click toggles the editor; gold border follows settings-open and
  Escape too. Right-click opens Heals settings. Combat closes the editor and
  locks the button, and combat exit restores access.

- Open the editor from settings. Inspect the fifteen-slot layout at normal and
  increased UI scales, spell/rank tooltips and unavailable-spell explanations.
  Compare tile sizes, gaps, colors and header styling beside Keybinds: no large
  backdrop, dialog title or footer. Confirm tile legends and remove controls stay
  readable over icons. Drag its header; close with the minimap button or Escape.
  Reload starts with the editor closed.
- Drop player spellbook heals of two different ranks. Verify exact ranks survive
  swapping and reload. Reject pet, passive, harmful, item and macro assignments.
  A friendly buff is supported because the client classifies it as helpful.
- Test pickup/click, drag/drop, swaps, outside cancellation and removal. Editor
  interactions and unlocked party previews must never cast.
- Test all fifteen combinations on player and party1-party4, including in combat
  and with both ActionButtonUseKeyDown values. Each gesture casts once, keeps the
  selected target unchanged and uses the clicked unit. Plain Left without an
  assignment or learned class default targets.
  Assign plain Left, Shift-Left and Ctrl-Left independently, then remove plain
  Left and confirm its default (or targeting without one) returns without affecting modified spells.
  Empty modified Left slots and unavailable assigned Left spells must do nothing.
- Test Alt and combined modifiers: no healing fallback. Remove a plain binding
  while retaining Shift and verify neither activates the other's spell.
- Test missing, dead, offline, hostile and out-of-range recipients with auto-self
  cast enabled and disabled. An invalid click must not redirect to target or self.
- Enter combat during a drag or edit. It cancels immediately, with no blocked
  action. Reload during combat and test deferred startup; spell changes defer
  until combat ends. Test roster changes and raid visibility as before.
- Load Apogee Keybinds too, with its Mouse 3-5 assignments active. Verify Heals
  row clicks do not also trigger global actions, and clicking elsewhere retains
  Keybinds behavior. Repeat with each addon loaded alone. If routing conflicts,
  do not call the affected combinations supported; record the exact collision
  before deciding any separate integration work. No sibling files were changed.

- On a Priest with no manual Left assignment, confirm Lesser Heal's highest
  learned rank appears and casts. Learning a new Lesser Heal rank updates the
  default outside combat. A manual lower-rank or other-spell override remains
  exact; removing it restores the default. Reload preserves this behavior.
  Classes without defaults and modified slots gain no default; no known candidate restores
  plain targeting. Confirm the default tooltip and absence of a remove control.
- On a Priest with no manual Right assignment, verify Power Word: Shield uses
  the highest learned rank. A manual override wins, removal restores Shield,
  modifiers remain separate and other classes gain no right-click default.
- On a Paladin without a manual Left assignment, verify Holy Light uses the
  highest learned rank. An explicit lower-rank assignment must remain unchanged.
- Verify first-name-only labels and the flush class strip for each party member,
  including class changes in reused slots, combat, offline and dead states.
- Use Reset position and check spacing beneath Tank's Forever player/target bars;
  existing saved positions must survive reload until explicitly reset.
