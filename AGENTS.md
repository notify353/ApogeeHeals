# Apogee Heals

- Independent Forever-only addon; other Apogee repositories are read-only references.
- Verify directory, branch, remotes and dirty state before changes. Preserve user work.
- Read docs/API_REFERENCE.md and run scripts/check-wow-api-export.ps1 before API work.
- Private addon namespace, Lua 5.1, native secret-capable display sinks and native secure actions.
- Never perform ordinary Lua calculations or comparisons on restricted values.
- Keep fixed unit tokens; do not modify protected layout or attributes in combat.
- No casting, profiles, extra settings or unrelated features without explicit scope.
- Run pwsh ./scripts/test-local.ps1. Report live acceptance separately from mocks.
- Preserve MIT notices. Publishing, pushes and releases require separate authorization.

## Local DEV installation workflow

- Requested addon changes include validated local DEV installation without a separate install prompt. This replaces the earlier direct child-install workflow; never overwrite canonical PROD from this repository or a child installer.
- The central Apogee distribution owner handles reviewed immutable child commit/file hashes in `distribution/candidate.lock.json`, aggregate checks, builds and the single installer. Do not include dirty sibling files implicitly. Docs-only commits do not change runtime pins or republish artifacts.
- Stable authority: `C:/Dev/WoW/ApogeePartyHealthBars/distribution/DUAL_WORKFLOW.md`. Run central commands from `C:/Dev/WoW/ApogeePartyHealthBars`, not a temporary prototype worktree.
- Central build: `python -B scripts/dual_distribution.py --sources-root C:/Dev/WoW --output <unique-artifact-dir>`.
- Central DEV install: `python -B scripts/install_dual_distribution.py --client-root "C:/Program Files (x86)/World of Warcraft/_classic_beta_" --sources-root C:/Dev/WoW --artifacts <same-dir> --backup <unique-backup-dir> --previous-install <latest-central-transaction.json>`. Never use `--initial-retrofit` for routine development.
- Preserve separate DEV/PROD identities and SavedVariables, unrecognized/user-modified files and verified rollback receipts. Verify installed bytes and report reload needs. Do not operate or restart the game. Offline checks and installation do not establish in-game acceptance.
