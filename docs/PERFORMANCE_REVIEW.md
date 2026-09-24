# Performance and lifecycle review — 2026-09-24

Scope: incremental review after the restricted-table and unavailable-spell fixes.
Installed/exported Forever remains 1.60.1.70009; strict freshness check passes.
Reviewed runtime event coalescing, aura/reminder work, binding application, hidden
picker updates and preview/drag OnUpdate lifecycle. No new API or persistent
data schema is introduced.

## Findings and fixes

- P2: a refresh queued before PLAYER_LEAVING_WORLD still queried and repainted
  the departed world after buff cleanup. Runtime refreshes now suspend while
  away, drain pending callbacks safely, and resume on PLAYER_ENTERING_WORLD.
  Rapid leave/enter before the callback preserves the arrival update.
- P2 performance: every refresh reconfigured all twenty reminder buttons and
  registered their visibility drivers even when nothing changed. Each button
  now remembers only its own public configured spell ID and setup flag. Changes
  still apply outside combat; combat painting never updates the configuration
  cache, so pending changes reconcile normally. No live aura object is cached.
- P3 performance: each watch's party scope was queried once per party row, and
  a previously opened hidden picker kept rebuilding its entries. Scope is now
  resolved once per watch within each synchronous refresh, and hidden pickers
  refresh explicitly on reopening. No observation survives into another event.
- P3 performance: binding application repeated resolution separately for each
  recipient. It now resolves a combination once and applies it to all five fixed
  recipients, retaining all modifier no-ops and unavailable-assignment behavior.

## Reproducible work counts

`lua tests/performance_spec.lua` uses five living units, ten public auras each,
one enabled party-capable watch, one manual binding, and an opened then hidden
picker. It runs 100 health events with one callback flush per event.
The same fixture was measured before and after the changes.

| Work | Before | After |
| --- | ---: | ---: |
| Aura API reads over 100 refreshes | 11,000 | 11,000 |
| Spell-info lookups over 100 refreshes | 200 | 100 |
| Self-buff scope lookups over 100 refreshes | 500 | 100 |
| Reminder visibility-driver registrations over 100 refreshes | 2,000 | 0 |
| Spell-info lookups for one binding application | 5 | 1 |
| Aura reads by queued callback after world exit | 55 | 0 |

The fixture also checks 100-event burst coalescing, changed-aura action clearing
and recovery, combat deferral, hidden-picker reopening, ordinary zoning recovery
and rapid leave/reentry. Existing tests cover restricted/unknown data, preview
isolation, saved data and native click actions. No extra polling/timers were added.

Full Lua 5.1 suite and current-export native click/visibility fixtures pass.
Actual Blizzard Lua functions execute with mocked engine inputs; these results
do not measure FPS, live CPU time, taint propagation or server aura behavior.
Aura scans remain fresh and bounded; no speculative cross-event caching or
layout redesign was introduced. No additional measured hot-path defect was found.

Local installation and rollback are recorded in HANDOFF.md. Still check live
buff appearance/removal, combat exit, zoning, picker reopen and healing clicks,
including Keybinds coexistence. Focus audio remains separate deferred work.
