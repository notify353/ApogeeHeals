# Isolated Classic Era adapter

The central Era builder selects ApogeeHeals_Era.toc, loads shared modules, then Era/Adapter.lua before startup. The adapter changes only the private addon namespace after central client/family admission. The standard TOC never loads it. No global API replacements, save imports or standalone installation.

Authority: Classic Era 1.15.9.70003, exported October 24, 2026. The central distribution/era/api-evidence.json records reviewed files and freshness. Never use stale leftovers or another flavor as authority. Frozen Forever tests are offline regressions; live Forever validation is unavailable after beta.

Run existing Lua specs plus tests/era_spec.lua and central Era generated-package tests. Only the central checked installer installs a reviewed DEV package after approval. Native actions, layout and persistence require user testing.
