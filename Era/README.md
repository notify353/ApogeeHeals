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
