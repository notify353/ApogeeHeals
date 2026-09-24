# Apogee Heals

- Independent Forever-only addon; other Apogee repositories are read-only references.
- Verify directory, branch, remotes and dirty state before changes. Preserve user work.
- Read docs/API_REFERENCE.md and run scripts/check-wow-api-export.ps1 before API work.
- Private addon namespace, Lua 5.1, native secret-capable display sinks and native secure actions.
- Never perform ordinary Lua calculations or comparisons on restricted values.
- Keep fixed unit tokens; do not modify protected layout or attributes in combat.
- No casting, profiles, extra settings or unrelated features without explicit scope.
- Run pwsh ./scripts/test-local.ps1. Report live acceptance separately from mocks.
- Installation, publication and releases require explicit approval. Preserve MIT notices.

- Standing owner authorization (2026-09-24): requests to change this addon include validated local WoW Forever installation without another installation prompt; this supersedes separate-approval requirements above for local installation only. Verify the actual Forever destination, preserve SavedVariables and unrecognized/user-modified files, keep a verified rollback backup, verify copied files and report reload needs. Do not operate or restart the game. Offline checks/installation do not establish in-game acceptance; publishing, pushes and releases remain separately authorized.
