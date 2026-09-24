# Heals quality review — 2026-09-24

Reviewed every loaded Lua module, TOC order, startup, saved-data handling,
event lifecycle, protected actions, UI behavior, existing cleanup diff and
test harness. Review itself performed no installation or live-client mutation;
the later authorized local installation is recorded in `docs/HANDOFF.md`.

## P2: readable table references can still forbid indexing (fixed)

`Core/Access.lua` previously checked only `issecretvalue` and `canaccessvalue`.
Spell/aura consumers then indexed returned tables outside the API call's error
boundary. The stronger mock reproduced an exception in `Bindings.Resolve`
when a readable reference prohibited indexing its contents. The refreshed
70009 FrameScript contract confirms this distinction.

The common helper now rejects tables unless `canaccesstable` succeeds. Startup
requires that API before saved-data changes or gameplay frame creation. The
export manifest now includes FrameScriptDocumentation. Spell info, cursor
spellbook info, buff scans and drinking recognition share this boundary.
Regressions cover forbidden indexing, clearing stale reminder actions on unknown
scans, readable-data recovery and the missing required guard. Native enforcement
itself cannot be established with mock tables.

## P2: unavailable optional spell namespace interrupted refresh (fixed)

A second regression reproduced `C_Spell=nil` throwing before the protected
lookup, contradicting safe unavailable-spell behavior. Binding and buff consumers
now guard namespace/enum availability before member access. Saved assignments
remain intact and inactive rather than falling back to targeting; restoring the
APIs restores the action. Tests also cover missing spellbook/enums and retained
observed party scope when self-buff classification is unavailable.

## P3: contradictory feature status documentation (fixed)

The changelog still called click-to-cast deferred, and the acceptance checklist
omitted the owner's recorded click-to-reapply confirmation. Corrected both
against the implementation and existing handoff. Full acceptance is still pending.

## Other reviewed boundaries

- TOC references exist and load the private modules before composition. Author,
  folder/TOC identity and SavedVariables remain stable. No addon dependencies,
  cross-addon global writes or bundled Blizzard source were found. There is no
  release archive/build pipeline in this repository; source/TOC checks alone do
  not verify a future distribution archive.
- Startup rejects other client families before saved-data writes and defers
  secure construction during combat. Unexpected construction exceptions have
  no rollback/retry transaction; arbitrary construction failures remain a
  hardening limitation. The reproduced optional spell-namespace failures have
  been fixed; missing table-access capability rejects startup cleanly.
- Secure actions use fixed unit tokens, explicit modifier no-ops and native
  spell/target actions. Attribute/layout updates defer in combat. Buff actions
  use native combat visibility, and preview rows never receive actions. Actual
  taint propagation, anchored-frame restrictions and engine dispatch remain live
  checks; mocks model only selected protected operations.
- Health, power and predictions pass opaque values to native display sinks.
  No ordinary arithmetic on those live quantities was found. Aura learning is
  bounded and requires complete observations; zoning clears candidates.
  UI refreshes coalesce, but each out-of-combat refresh still scans up to five
  units for both drinking and buffs. No measured performance defect was found.
- Storage sanitizes bindings, positions and buff records, migrates older numeric
  schemas and rejects newer numeric schemas. Tests cover overrides, disabled
  reminders, rank changes and reload persistence. No player identities or live
  aura objects are persisted. Synthetic preview state stays separate.
- Heals starts independently. Mouse 3–5 with Keybinds remains an explicit live
  coexistence check because that addon claims global inputs. Existing placement
  constants reference Tank visually without reading its runtime.
- Inherited drink/default IDs are client-validated candidates, not evidence of
  an obsolete Era runtime. No additional justified feature removal was found.
- Focus audio is still unimplemented. The previous health-readability diagnostic
  has no reported result. This guard fix does not establish a supported health
  threshold/audio replacement. No restricted-value workaround was introduced.

## Verification and remaining live checks

The owner's refreshed export was independently checked against installed beta
**1.60.1.70009**. All seventeen required files postdate `WowB.exe`
(**2026-09-24 22:04:15 UTC**). Product metadata matches the executable.
Reviewed current table-access, aura and spellbook contracts; actual exported
secure click/target/spell/visibility code is exercised by the native fixtures.
The earlier stale-export blocker is resolved. No prior export hashes were stored,
so no byte-for-byte comparison with the overwritten export is claimed.

Both `pwsh ./scripts/check-wow-api-export.ps1` and the complete
`pwsh ./scripts/test-local.ps1 -ForeverExportPath
'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'`
pass, including the previously failing access regression, Lua 5.1 parsing, TOC
and whitespace checks. Native-source fixtures ran against the current export;
they still supply mocked engine inputs and cannot validate actual taint or visuals.

No additional confirmed actionable defect remains from this review. Current-build
combat reloads, all click modifiers, protected geometry, prediction rendering,
server buff/drink coverage and Keybinds mouse-button coexistence still require
the acceptance checklist in the actual client. Focus audio remains a separate
unimplemented request. No integration, commit or publication occurred. The later
local installation does not change the live acceptance status.
