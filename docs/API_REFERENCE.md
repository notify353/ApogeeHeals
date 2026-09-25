# Forever API authority

Matching local source:
`C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns`.
Build 1.60.1.70009, project 1, interface 16001; checked 2026-09-24.
Metadata and required source files are in wow-api-export.json. The checker is
read-only and fails on a changed installed build or stale/missing export. Export
timestamps are a freshness heuristic, not proof of runtime compatibility.

## Forever-only cleanup review (2026-09-24)

The installed executable and product metadata agree on 1.60.1.70009. All seventeen
required export files postdate the executable. Rechecked the native health and
incoming-heal display contracts, guarded aura/spellbook reads, self-buff
classification, secure click dispatch and visibility source. The recorded build
and runtime warning baseline now match this review; live acceptance is separate.

Heals already has a Forever-only family/interface gate, one TOC and no Era
runtime branch or cross-addon dependency. No feature or module removal is
supported by this audit. Keep the inherited drink and class-default spell IDs:
Forever resolves and validates them before use, and the export cannot prove
server spell/aura coverage. Keep native target/spell actions and restricted-value
guards. The `_classic_beta_` directory and `wow_classic_beta` product are the
actual Forever installation identifiers, not obsolete Era compatibility paths.

Author metadata, technical identity, saved data and existing feature-folder
organization already match the shared Apogee convention. Historical attribution
and MIT notices remain intact. Focus audio and live range detection remain
deferred work, outside this cleanup.

## Current table-access review

The refreshed 70009 FrameScript contract still distinguishes access to a value
from permission to index table contents. The common access helper now checks
`canaccesstable` after value guards and before consumers index spell, spellbook,
aura or class-color tables. Startup requires that guard. FrameScriptDocumentation
is now included in the export freshness manifest. Shared spell/aura consumers
also tolerate missing spell namespaces/enums without losing saved assignments.
Relevant current signatures and native dispatch remain compatible with the
reviewed behavior. The old manifest did not store hashes, so this is a contract
review and current-source execution, not a claim of byte-identical exports.

## Contracts used

- InputDocumentation.GetCursorPosition returns screen coordinates;
  SimpleFrame.GetEffectiveScale and SimpleScriptRegion.GetCenter supply the
  minimap-local conversion. GetCenter may return nothing or secret coordinates;
  all cursor/center/scale/dimension inputs are checked for public finite values
  before calculation. GetFrameLevel is also aspect-secret: placement defers
  unless its public finite integer permits the shared +20 level offset.
  RegisterForDrag("RightButton") activates temporary
  OnUpdate sampling. HookScript("OnSizeChanged") preserves existing map handlers.
  Placement uses a constant circular radius (half the larger dimension + 20)
  and default angle 260. Only actual valid drag updates persist minimapAngle.
  Resize/world/scale/combat-exit events refresh position without permanent polling;
  combat, hiding and leaving the world cancel drag sampling and owned tooltips.

- Paladin default reminders use ordinary Might candidate ranks 25291, 19838,
  19837, 19836, 19835, 19834, 19740 and Wisdom 25290, 19854, 19853, 19852,
  19850, 19742, highest first. As with existing healing defaults, every selected
  rank must resolve through readable C_Spell.GetSpellInfo, both player-bank
  IsSpellInSpellBook(includeOverrides=false) and IsSpellKnown, and active,
  helpful, non-harmful validation. The export proves these API contracts, not
  the server's spell database; actual identities and availability are checked
  on the running client. No level-based spell grant is assumed. Greater and
  other ordinary blessing IDs are coverage/exclusivity candidates only, never
  automatically granted actions. Seeding/rank migration defers in combat.
- Blizzard_ActionBar/Shared/SpellFlyout.lua uses native
  GameTooltip:SetSpellByID(spellID, false, true) after SetOwner; the final true
  requests spell subtext. Reminder tooltips use the same native method with the
  public configured ID. OnLeave, OnHide, roster changes and icon replacement
  clear only the tooltip owned by that button. Combat clears presentation,
  without changing protected action attributes.

- Readable player labels omit surnames using the client's surname separator,
  with whitespace/hyphen fallback. Restricted or unavailable identities display
  blank; they never enter Lua string operations. Camelot NameUtil confirms that
  UnitName's first return can contain both first name and surname. Current-build
  live validation is pending.

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
- Buff discovery uses UNIT_SPELLCAST_SUCCEEDED's public player/spell identity
  as a ten-second candidate. A complete HELPFUL scan must then find that exact
  aura ID, a public player sourceUnit (literal player or UnitIsUnit alias), and
  a finite public duration >= 300 seconds. There is no static buff catalog.
  IsSpellKnown/in-spellbook/helpful/non-harmful/non-passive checks exclude
  unlearned and non-player actions. Discovery and reminders run outside combat.
  Coverage uses readable IDs/names from a full scan, regardless of caster;
  unreadable or truncated scans establish neither absence nor new learning.
  Duration and source are never inspected before access guards. No remaining
  time calculation, cast-success assumption of coverage or combat snapshot is used.
  Learned ranks with identical client names share a watch entry; differently
  named effects remain separate. C_Spell.IsSelfBuff classifies self-only effects;
  a readable false enables party coverage immediately, including existing learned
  buffs. A readable true limits coverage to player. Unknown values fall back to
  observed party application. Spell identities, enabled
  flags and this scope persist, never aura objects, recipients or timers.
- Each visible buff reminder has its own SecureActionButtonTemplate with an
  immutable row unit. Out-of-combat refresh installs the learned spell ID and
  type1=spell, or clears both. LeftButtonUp/useOnKeyDown=false produces one
  release action; modified left clicks explicitly do nothing. Native visibility
  drivers hide reminders in combat. Combat cleanup touches only icon artwork,
  not protected buttons or attributes. Preview clears reminder actions outside
  combat. The matching-source test exercises native dispatch for all five units.
- SecureTemplates.lua/xml: SecureActionButtonTemplate, unit/type1 attributes,
  native target action. Explicit useOnKeyDown=false pairs with LeftButtonUp,
  regardless of the user's ActionButtonUseKeyDown setting. Optional healing actions
  register Left/Right/Middle/Button4/Button5 releases and install modifier-specific
  type/spell attributes outside combat. The existing explicit unit wins before
  self/focus casting checks. Exact IDs reach the native SECURE_ACTIONS.spell path.
  Empty strings explicitly block unsupported Alt/combined modifiers; cleared
  assignments restore a learned class default, otherwise clear type and spell;
  plain Left without either restores target.
  An unavailable saved Left assignment stays a no-op; it does not target instead.
  No unit click-binding registration,
  global override bindings, SecureUnitButton binding dispatch, or restricted snippets.
- SpellBookDocumentation: IsSpellInSpellBook(Player, includeOverrides=false) and
  IsSpellKnown gate exact player spell IDs. Cursor fallback resolves a player-book
  index through GetSpellBookItemInfo. SpellDocumentation supplies helpful/harmful/
  passive validation, icon/name and GetSpellSubtext rank labels. Public-read guards
  precede inspecting returned values. Helpful classification includes friendly buffs;
  it is not a healing-effect classifier. Manual assignments retain exact ranks.
- Class defaults contain Priest plain Left (Lesser Heal candidates 2053, 2052,
  2050) and plain Right (Power Word: Shield candidates 10901, 10900, 10899,
  10898, 6066, 6065, 3747, 600, 592, 17), resolved highest-first through learned/helpful
  checks. UnitClass's class token must be public. Defaults never write storage;
  manual entries take priority even when unavailable. Spellbook refreshes apply
  outside combat; these candidate identities need live confirmation on Forever.
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
