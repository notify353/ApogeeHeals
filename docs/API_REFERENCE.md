# Forever API authority

Matching local source:
`C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns`.
Build 1.60.1.69913, project 1, interface 16001; checked 2026-09-20.
Metadata and required source files are in wow-api-export.json. The checker is
read-only and fails on a changed installed build or stale/missing export. Export
timestamps are a freshness heuristic, not proof of runtime compatibility.

## Contracts used

- Blizzard_Fonts_Shared/Shared/GameFonts.xml defines Number12Font, a native
  locale-aware sans-serif family used for preview-handle text. Names retain the
  original GameFontHighlightSmall font at 8 logical pixels for readability.
- UnitClass's class filename is passed to C_ClassColor.GetClassColor only when
  readable. The returned ColorMixin supplies GetRGB for name text. Unknown,
  restricted or unavailable classes reset to white, preventing stale slot colors.
- Full-party preview uses independent unprotected frames anchored to the live
  root, sharing its row construction and fixed geometry. Frame SetAlpha (documented
  AllowedWhenTainted) temporarily fades the live rows without modifying secure
  visibility drivers. A mouse-enabled preview frame consumes clicks over samples.
  Combat hides the preview and restores alpha; sample data never enters live reads,
  calculators, discovery or storage. No protected show/hide/anchor changes occur.
- UnitHealPredictionCalculatorAPI/SharedDocumentation: a calculator per row,
  Default maximum health, MissingHealth incoming clamp, overflow ratio 1, and
  ReducedByIncomingHeals absorption mode. UnitGetDetailedHealPrediction samples
  the unit with no healer filter; GetIncomingHeals supplies only its first return
  (combined amount) to SetValue. All restricted quantities remain native inputs.
  The preview is anchored once to the health fill texture's right edge, at the
  same fixed width/height, and clipped by the health frame. There is no Lua
  arithmetic or combat-time reanchoring. UNIT_HEAL_PREDICTION and
  UNIT_HEAL_ABSORB_AMOUNT_CHANGED invalidate the event-driven presentation.
  ResetPredictedValues prevents failed/empty samples from retaining stale data.
- UnitDocumentation: health/power/name reads, connection/death state, unit events.
  UnitHealthPercent evaluates the health-color curve natively. Restricted values
  go directly to display sinks, never Lua calculations, table keys or storage.
- SimpleStatusBarAPIDocumentation and SimpleFontStringAPIDocumentation:
  SetMinMaxValues, SetValue, SetStatusBarColor and SetText support native display.
- UnitAuraDocumentation: C_UnitAuras.GetAuraDataByIndex(unit, index, HELPFUL)
  requires aura access and can return restricted data. Both aura objects and
  identity fields are checked before ordinary Lua use. Missing optional aura
  access disables the drinking claim while health frames continue working.
- SpellDocumentation: C_Spell.GetSpellInfo resolves each candidate ID to this
  client's spell ID and localized name; unresolved candidates are not used.
- SecureTemplates.lua/xml: SecureActionButtonTemplate, unit/type1 attributes,
  native target action. Explicit useOnKeyDown=false pairs with LeftButtonUp,
  regardless of the user's ActionButtonUseKeyDown setting. No unit click-binding
  registration, SecureUnitButton binding dispatch, or restricted snippets.
- Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua: native visibility
  resolution for `[group:raid] hide; [@unit,exists] show; hide`. Native handling
  owns combat roster visibility; the addon never changes those attributes then.
- Keybinds UI/Settings.lua is a read-only reference for native AddOns category
  registration. Tank UI/Style.lua, Core/Access.lua and Core/UnitAPI.lua are the
  appearance and restricted-value implementation references, not dependencies.

## Optional matching-source tests

```powershell
pwsh ./scripts/test-local.ps1 -ForeverExportPath 'C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns'
```

These read the local source and execute its exact click-dispatch functions,
target action and visibility resolver with mocked engine inputs. Without a
path this portion explicitly reports SKIP; a supplied invalid path fails.
Blizzard source is neither copied into this repository nor redistributed.
Tests do not reproduce secure engine execution, taint, condition parsing,
restricted-value enforcement, rendering or server-specific drinking auras.

Routine build changes within the same Forever family warn and use capability
checks at runtime. Development still requires a fresh matching export review.
