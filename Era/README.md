# Isolated Classic Era adapter

The central Era builder selects ApogeeHeals_Era.toc, loads shared modules, then Era/Adapter.lua before startup. The adapter changes only the private addon namespace after central client/family admission. The standard TOC never loads it. No global API replacements, save imports or standalone installation.

Authority: Classic Era 1.15.9.70003, exported October 24, 2026. The central distribution/era/api-evidence.json records reviewed files and freshness. Never use stale leftovers or another flavor as authority. Frozen Forever tests are offline regressions; live Forever validation is unavailable after beta.

Run existing Lua specs plus tests/era_spec.lua and central Era generated-package tests. Only the central checked installer installs a reviewed DEV package after approval. Native actions, layout and persistence require user testing.

Era.5 adds a separate live threat-stack aura reader because Era lacks Forever's
CustomAuraContainerTemplate. Fixed icons show the player's Sunder Armor, Thunder
Clap and Demoralizing Shout across Classic ranks. Sunder displays stacks above
one, or ? if the aura is confirmed but its count is unreadable. Other casters
do not count. Unknown/failed scans clear live icons; a blank is not proof that
the effect is absent. The shared stable rows and 0.1-second refresh remain.

Threat demo is scripted and does not read live auras. The live reader reuses
preallocated fixed artwork, makes no protected changes in combat, and never
modifies global aura APIs. This correction covers the tank threat stack only.
## Era.6 party debuffs and cleansing

Era.6 supplies the missing public-aura display for player/party rows and the
friendly target: eight debuff icons in native order and cleansing highlights
for learned player spells. The archived Era aura/dispel readers identified the
missing native-container dependency; no archived runtime or settings are loaded.
All icons are preallocated. Combat changes artwork only, never the fixed secure
recipient/spell or geometry. A bounded, complete scan detects dispel types beyond
the eight displayed icons; failed/restricted/truncated snapshots clear artwork.
Tooltips are read-only and out of combat. Preview, death, target changes and
world transitions clear stale visuals. Pet cleansing remains intentionally absent.
