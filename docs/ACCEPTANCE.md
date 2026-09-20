# In-game prototype acceptance (pending)

The owner approved test installation and confirmed incoming heals visible in game.
Visual iterations were reviewed during testing; the complete checklist below remains
pending. Further installation changes require authorization. Local mocks and export checks
do not complete any of these checks.

- Login and reload outside combat: player row appears, locked, with correct name,
  health and active resource. Repeat a reload during combat; construction waits
  until combat ends without blocked actions.
- Add/remove each party member, including during combat. Verify names and fills
  follow native unit tokens; click every displayed row and confirm the target.
- Check left-click targeting with ActionButtonUseKeyDown enabled and disabled.
  Verify no custom spell action, right-click action or click-binding registration.
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
