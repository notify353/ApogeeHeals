# Forever API authority

## Relative threat bar prototype (70170, 2026-10-02)

Owner solo screenshot: 133 attempts, 119 periodic polls, 24.7 seconds combat,
first/last attempts at 0.0/23.8 seconds, longest gap 0.9 seconds; all seven read
and native-call checks passed. This establishes the observed solo access only.

Rechecked the fresh export and native UnitFrame_UpdateThreatIndicator. Its
numeric display selects rawPercentage, replacing it with
UnitThreatPercentageOfLead while isTanking is true, and hides zero. Added that
source to export freshness checks and matching-source assertions. The new
prototype mirrors the selector only when the boolean is publicly readable.
Restricted percentages pass directly to SetValue and SetFormattedText; restricted
selectors leave NO DATA rather than branching. Numeric invalid/missing inputs
clear stale fill. Tank lead zero shows NO COMPARISON, not zero threat or safety.

Fixed native range 0-200, left-to-right fill and a center tick at 100 provide a
reviewable scale without numeric transforms. The label shows the original native
percentage above the visual cap. No equal-threat, pull threshold, competitor
identity or seconds-to-loss claim is made from this undocumented percentage.
Native aggro/lead warnings remain separate and determine row colors. Seven
stable slots, target deduplication and diagnostics are unchanged. All layout is
created outside combat; no protected actions or layout writes were added.

This supersedes the earlier disabled-continuous-bar presentation, under explicit
owner approval to build a prototype using native percentage selection. It does
not resolve the export's missing numeric definition. Validate with a competitor
building and losing threat, and solo/no-comparison cases; compare against native
numeric threat. Mocks check selection, direction, cap contract, missing/secret
fallbacks and clearing; actual rendering and group semantics remain pending.

## Combat threat diagnostics (70170, 2026-10-02)

Rechecked the fresh export before implementation. UnitDetailedThreatSituation
returns isTanking, status, scaledPercentage, rawPercentage and rawThreat;
UnitThreatLeadSituation and UnitThreatPercentageOfLead add independent values.
Probes use fixed player/target tokens. Access.Readable guards Lua inspection;
restricted values reach only native SetFormattedText or boolean-to-alpha sinks.
Only public success flags and failure categories are retained, never raw values
or native readbacks. Sinks clear immediately. Display-call PASS confirms no
thrown exception, not rendering, taint safety or percentage semantics.

The session-only setting is independent of the threat stack. Events and a
0.2-second combat-only poll sample confirmed living attackable targets. Failures
latch until next combat. Combat exit stops polling and freezes screenshot results.
World exit suspends/freezes; disabling, reload and Defaults clear the session.
Target gaps are skipped; no samples means dashes, never PASS. Mocks cover secret
passthrough, failure latching, freeze and lifecycle. Native combat behavior and
screenshot usability still require owner acceptance.

Coverage counters use only public frame elapsed time and observation counts.
They distinguish API attempts from skipped target gates and periodic polls from
event samples. First/last timestamps are elapsed seconds since collection began;
longest gaps include initial/trailing gaps and frame stalls. All freeze with the
results. Tests simulate sustained combat, target gaps and a late API failure.
An API attempt counts even if it returns missing/error; per-field FAIL retains
that distinction. Solo results do not establish behavior with threat competitors.

## October 1 client identification correction

The fresh 70170 export defines WOW_PROJECT_CAMELOT = 18 and assigns
WOW_PROJECT_ID to it in the Camelot ProjectConstants module. Its TOC selects
that module for the camelot game type. Project 1 is only a legacy Forever
identification fallback when version is 1.60.x, not a mandatory current ID.
Runtime interface and patch numbers do not expire features: native Forever
identity is accepted across version/interface changes, followed by required API
checks. Other client families remain unsupported. Prior project-1-only policy
and exact-interface statements below are historical and superseded.

Current export contracts were inspected for the affected identity path. In
Keybinds' changed Spell/Unit/SlashCommands sources, spell data remains nullable
and restricted where annotated, cast event identifiers remain guarded, and native
command registration remains the authority. This is a current-contract review,
not a complete old/new diff or native acceptance.


## Default-off threat stack (70170, 2026-10-01)

Reviewed current UnitDetailedThreatSituation, UnitThreatLeadSituation,
UnitThreatPercentageOfLead and UnitIsUnit declarations in the owner's fresh
70170 export. The restriction contracts and native warning definition remain
as described below. Matching-source tests verify current native lead dispatch,
secret-capable text/bar/alpha sinks and existing healing contracts. The freshness
check covers all required files. Interface remains 16001. This changes the default
enable decision, not threat interpretation; native acceptance on 70170 is pending.

## Minimal tank threat stack (70124, 2026-09-29)

Reviewed the refreshed local 1.60.1.70124 export; all required sources postdate
the current executable. Existing native-contract tests run against this export;
earlier sections retain their historical review dates. The freshness manifest
and runtime warning baseline now use 70124, with interface 16001 unchanged.

UnitThreatLeadSituation(player, mob) returns 0-3: none, yellow, orange, red.
Its documentation explicitly says red when the player is not first on threat.
CompactUnitFrame's tank path calls this API and combines 1/2 into GAINING_THREAT_COLOR.
The panel labels those public states WEAK LEAD, and 3 NO LEAD. A readable
UnitDetailedThreatSituation isTanking=false with a valid status shows NO AGGRO.
Lead readings are independent of detailed readings: native state 0 shows LEAD
even if detailed participation is unavailable. A separate AGGRO/NO AGGRO/AGGRO ?
line prevents lead from implying aggro. Missing or malformed lead shows UNKNOWN.
Restricted lead goes directly to SetFormattedText("RISK %.0f/3") and SetValue
on a reverse-filled, Immediate 0-3 warning bar. This is a discrete native warning
scale (0 none, 1 yellow, 2 orange, 3 red), not a margin or percentage. Restricted
isTanking uses native boolean-to-alpha for separate precreated aggro labels.
Detailed threatValue goes directly to native SetFormattedText("Threat %.0f");
no Classic divide-by-100 scaling is applied on Forever. Failed sinks clear their
presentation. No restricted number is formatted, compared or cached by Lua.
A previously tracked hostile mob whose readings become unavailable stays
in its slot as UNKNOWN. The reserved selected-target row is active only during
player combat; idle selection shows no placeholder. An untouched hostile target
selected during combat may show UNKNOWN. Stable encounter rows remain independent.
The documented MayReturnNothing contract cannot establish an exact zero threat.
Fresh mobs with a readable nil status and no lead reading are not admitted.
An independently available lead reading establishes participation for tracking.
Uncertain participation/hostility is conservatively shown as UNKNOWN, not classified
as safe or silently discarded. Readable dead/friendly/missing units are cleared.

UnitThreatPercentageOfLead is present and restriction-marked but has no numeric
definition in this export. TargetFrame uses it while tanking and rawPercentage
otherwise; that does not establish a continuous equal-threat-centered transform.
Both numeric values and threat states may be secret. No native numeric transform
or live dungeon test establishes the requested center semantics, so continuous
movement is disabled. This prototype uses labeled discrete warnings, no simulated progress.

Reference review (2026-09-30): Threat Plates 13.3.0-beta3 explicitly supports
Forever, selects the unscaled modern detailed-threat API and disables legacy
off-tank/heuristic paths on its modern API surface. Its source is GPLv3 and was
reviewed as a reference only; no code was copied. References:
[Forever release](https://github.com/Backupiseasy/ThreatPlates/releases/tag/13.3.0-beta3),
[API selection](https://github.com/Backupiseasy/ThreatPlates/blob/b585e39b31fe46eb2c6414be14f695a258da9148/Init.lua),
[heuristic restrictions](https://github.com/Backupiseasy/ThreatPlates/blob/b585e39b31fe46eb2c6414be14f695a258da9148/Modules/Threat.lua).
This review does not establish what the user's live solo APIs return. The
reported UNKNOWN case remains a live retest requirement after the sink fix.

Nameplate added/removed events own token lifetimes; bootstrap reads GetNamePlates
and the matching NamePlateBaseMixin:GetUnit only after a public IsForbidden=false.
No nameplate internals, GUIDs or names serve as keys. Public acquisition sequence
fills seven fixed slots without rearranging survivors; overflow waits in that
sequence. A separately reserved eighth row uses fixed target and native duplicate
suppression. Event refresh plus a bounded 0.2-second active refresh rereads current
values; disabling/world exit clears tracking and stops polling. No restricted
threat result is cached. Only position and the enable toggle enter SavedVariables.
The panel defaults off. Only an explicit saved true enables tracking, presentation
and polling; the Tank threat stack settings checkbox is unchecked by default.
Existing explicit choices persist, and character Defaults restores the off state.

UnitIsUnit may return a secret boolean. EvaluateColorValueFromBoolean and SetAlpha
are AllowedWhenTainted; conversion feeds the highlight's alpha directly. Seven
precreated native alpha parents suppress the reserved target when any stable row
matches, without addon boolean combination, alpha/visibility readback or combat
layout writes. Unavailable comparisons clear highlighting and suppress the reserved
row with Target match unknown. Exact overflow deduplication uses public matches
only; secret matches use an honest total tracked count. UnitName reaches native
text sinks via existing PaintFullName. GetRaidTargetIndex has SecretReturns=true:
only a readable 1-8 index draws its marker; unavailable markers clear stale icons.

Mock tests cover state distinctions, secret/malformed results, stable slots,
normal target changes, overflow, token reuse, native boolean passthrough, polling,
zoning, disabled state, dragging, persistence and reset isolation. Matching-source
tests execute Blizzard's tank lead dispatch and verify the sink/event contracts.
They do not reproduce engine restrictions or establish early-warning timing.

Live acceptance after DEV activation: enable enemy nameplates, pull multiple mobs,
Tab normally and verify the yellow target outline moves while other rows stay put.
Observe a competitor approach and exceed your threat, then lose/recover aggro;
compare WEAK LEAD/NO LEAD/NO AGGRO with native Blizzard indicators. Record whether
WEAK LEAD precedes actual loss; there is no promised threshold or warning interval.
Check target outside the first seven, restricted-name/marker/comparison behavior,
threat wipes, dead/despawned mobs, zoning and out-of-combat dragging/reload.
Live engine rendering, taint and warning timing remain pending owner acceptance.

## Restricted unit names (70009, 2026-09-27)

Target, target-of-target and party labels pass UnitName's first return directly
to FontString:SetText, including restricted names. A public, nonempty surname
uses SetFormattedText("%s%s%s", name, separator, surname) to preserve Camelot
composition without Lua concatenation. An unreadable optional surname uses the
first name alone; the addon cannot safely decide whether that suffix exists.
Missing names or API/sink errors clear stale text. No text is read back.

The matching SimpleFontStringAPIDocumentation marks both sinks
AllowedWhenTainted with SecretArgumentsAddAspect Text. This supersedes the older
blank-on-restricted identity policy below. Classification, level fallbacks,
fixed unit tokens and protected combat layout/actions are unchanged.
Mock tests cover restricted names on both target rows during combat, surname
fallbacks and recovery. Matching-export checks verify the sink contracts;
actual five-player dungeon rendering and taint remain live acceptance checks.

## Inset side-icon geometry (70009, 2026-09-27)

Shared icons use 18 logical pixels at the existing 2x row scale, matching the
36px settings tiles. Two logical pixels between tiles match the settings 4px
gap. The -0.75 top offset centers them in the 19.5-high health/power cluster;
adjacent rows leave seven displayed pixels between tiles. Icon artwork is inset
one logical pixel, with gold background borders contained inside the tile.
Buff choices, reminders, cleanse siblings/indicators, native debuffs, food/drink
and weapon displays all use this geometry. Native flow children keep their
internal zero offset; only each strip anchor is vertically inset. No action,
filter, protected combat layout or restricted-data contract changes. This
supersedes the earlier full-height icon dimensions below.

## Class support (70009, 2026-09-27)

See [class support and live acceptance](CLASS_SUPPORT.md). Direct cleansing now
uses class-specific public action counts and exact learned ranks. Priest Dispel
Magic alone permits dual helpful/harmful classification in a cleansing-local
resolver; healing assignment validation is unchanged. Native HARMFUL filters and
permanent secure siblings retain the existing no-readback contract.

Independent curated upkeep uses complete public scans and exact family IDs.
Resolution is cached only within one refresh, including failures. Hunter aspects
reuse the matching StanceBar contract; native own selection, not another aura,
controls the player-only picker. Repeated unchanged choice rendering does not
rewrite protected visibility/attributes.

WeaponUpkeep uses CustomAuraContainer AddItemEnchantment with the exported
MainHand/OffHand constants, fixed player ownership, native inventory tooltip and
SetDurationText. It never reads enchantment fields, visibility or duration. A
native combat visibility parent hides the two fixed containers; inbound disable
clears their presentation on world exit/combat. No item application is added.
The enchantment implementation and PaperDollInfo documentation are now freshness
inputs. SecureTemplates pet action has fixed-unit dispatch but no expected-spell
identity gate for the slot; Devour Magic remains deferred.

## Friendly target support controls (70009, 2026-09-27)

The selected target (not targettarget) now shares upkeep reminders, Paladin
blessing choices/recommendations, learned cleansing actions and native debuff
icons. A SecureHandlerStateTemplate parent uses the fixed native visibility
condition [@target,help,nodead] show; hide. The health bar remains independently
visible for hostile targets. All support children inherit the friendly gate;
Blizzard owns combat visibility. No Lua friendship comparison changes protected
layout, visibility or action attributes in combat.

Out-of-combat target buff scanning requires guarded UnitCanAssist(player,target)
true plus the existing alive/readable-complete-scan checks. Unknown/hostile/dead
state yields no suggestions. Target is a fixed action unit, never copied from a
name or GUID. Learned party upkeep is offered, and self-only upkeep is allowed
only when readable UnitIsUnit(target,player) is true. Target scans do not expand
saved buff discovery. The personal aura picker stays solely on the player row.
No target drinking indicator is introduced; target debuffs sit immediately after
cleansing buttons, without reserving a cup gap.

Target UNIT_AURA/faction/flags/connection events request the existing refresh.
PLAYER_TARGET_CHANGED immediately clears owned buff/cleanse tooltips and old
buff artwork, then refreshes choices outside combat. It invokes native inbound
UpdateAllAuras on both target containers, including during combat, without
reading native aura state. The matching ManagedAuraContainer shared method
marks a FullAuraRebuild; AuraContainer explicitly documents external refresh for
target changes. Cleansing actions remain fixed-target secure siblings with
separate native indicators. Spell and preview changes still defer in combat.
Matching-source cast tests now exercise the selected target as well as party.

Source/package mocks verify parenting, help/nodead driver expression, target
switches, unknown/dead cleanup and native refresh requests. They do not prove
native engine visibility, restricted aura handling or physical input. Verify
friendly-to-hostile-to-friendly switches in/out of combat on the actual client.

## Blessing suggestion border (70009, 2026-09-27)

See [research and decision table](BLESSING_GUIDANCE.md). UnitGroupRolesAssigned
uses guarded Access.Read before any role comparison; UnitClass tokens also pass
readability checks. Assigned tank/healer overrides class; absent/unknown/restricted
roles use public class defaults. The local UnitDocumentation, PartyInfoDocumentation
PLAYER_ROLES_ASSIGNED event and CompactUnitFrame usage are freshness-checked.
Only one suitable offered spell is suggested. Normal versions precede Greater;
no Salvation, Light, Sanctuary or emergency spell is a generic fallback.
A one-pixel yellow texture and tooltip explanation affect presentation only.
Role changes use the existing out-of-combat refresh; combat clears artwork and
never updates secure attributes. Unknown aura snapshots show no choices/highlight.
Physical rendering/clicks and actual role delivery remain live checks.

## Per-recipient blessing choices (70009, 2026-09-27)

A complete public out-of-combat HELPFUL scan establishes absence of any recognized
lasting Paladin blessing on player/party1-4. Unknown/incomplete scans suppress
choices. Each unblessed row offers the highest learned rank of Might, Wisdom,
Kings, Salvation, Sanctuary and Light, with ordinary and Greater spells as
separate choices. Protection, Freedom and Sacrifice are emergency abilities:
they are neither upkeep choices nor evidence of a lasting party blessing.
Each candidate passes native spellbook and helpful-spell validation before use.

This replaces the single configured blessing recommendation, while retaining
saved reminder entries and unrelated upkeep discovery. All choices are visible,
independent of the four-reminder cap and old reminder checkboxes. Each secure
button has the immutable row unit, exact spell, release-only click and blocked
modified clicks. Tooltip and native action contracts are unchanged. No automatic
choice or casting occurs. A lasting blessing from any caster suppresses that row's choices.
Regular upkeep, blessing choices and the self-only aura choices share matching
geometry without overlapping. Combat hides choices through native drivers;
no protected attributes or layout change in combat. Mock source/package checks
cover five recipients, rank updates, all variants, unknown reads and cleanup;
physical input, native appearance and server coverage remain live checks.

## Paladin own-aura picker (70009, 2026-09-27)

Matching Blizzard_ActionBar/Shared/StanceBar.lua consumes GetNumShapeshiftForms
and GetShapeshiftFormInfo (texture, isActive, isCastable, spellID). Out of combat,
readable bounded form count, boolean active state and public spell IDs establish
whether the player's own Paladin aura is off. Any unreadable/incomplete result
suppresses choices. Each offered spell also passes the existing learned helpful
spell validation. Another Paladin's aura buff is not the player's selected stance.

Only the player row creates normal secure spell buttons for these choices,
with fixed player unit, LeftButtonUp and blocked modified clicks. Buttons match
the side icon geometry and follow up to four buff reminders (plus overflow space).
Native visibility drivers hide them in combat; combat cleanup changes artwork
only. Form events, normal aura refresh, spell changes and combat exit reevaluate
outside combat. Preview/world exit suppress the picker. Native spell tooltip and
cast dispatch follow the existing buff-button contract. No automatic selection,
restricted aura calculation, combat attribute/layout change or new setting.
Mock checks are not native physical-click/stance-event acceptance.

## Food/drink indicator tooltip (70009, 2026-09-27)

Resolve ordinary Food candidate IDs 433, 434, 435, 1127, 1129 and 1131 on the
client using the same guarded spell-name validation as Drink. The complete
readable out-of-combat HELPFUL scan accepts either category; Well Fed is not
an eating signal. When both are active the first matching aura in native scan
order supplies the artwork, timer and tooltip. Server-specific coverage needs
live acceptance. Food candidates are cross-checked against
https://wow-forever.gg/db/spells/1131-food/ and validated on the current client.

The normal frame enables hover only for live player/party indicators. OnEnter
rescans for a current public aura instance and calls GameTooltip:SetOwner then
SetUnitAuraByAuraInstanceID, matching Blizzard_BuffFrame/BuffFrame.lua and the
TooltipDataHandler method map. Native code populates the actual aura tooltip;
no tooltip fields are inspected. Refresh updates an owned tooltip without hiding
and reshowing the indicator. OnLeave/OnHide, aura loss, combat and world exit
clear only this indicator's owned tooltip. No cancel action or cast is added.
Mocks cover food-only and drink, fresh tooltip identity, ownership and cleanup;
actual hover rendering and food coverage remain in-game checks.

## Drinking countdown (70009, 2026-09-27)

The existing complete, readable HELPFUL scan still establishes drinking only
outside combat. Its matching auraInstanceID must be public before GetAuraDuration
is called. That native duration object passes directly to a DurationTextBinding;
no duration fields, remaining times or text are read, calculated or stored by Lua.
SetFormatter uses a native NumericRuleFormatter with threshold zero, step one,
rounding Up and format %.0f, preserving whole remaining seconds with no suffix.
The binding updates the cup's horizontally and vertically centered
FontString every 0.1 seconds natively; no addon OnUpdate polling is introduced.
Zero and expired durations format as empty text. Failed/missing duration support
retains the confirmed cup with no timer. Aura loss, incomplete scans, combat entry
and world exit disable the binding and clear its text. Preview and target rows
create no bindings. The cup remains outside the bar at the user's revised request.

Mock checks cover fixed recipients, native-object passthrough and lifecycle cleanup.
Actual countdown formatting, alignment and early-stop timing remain live checks.

## Player/party debuff display (70009, 2026-09-27)

CustomAuraContainerTemplate exposes an untainted inbound AuraContainer with
SetUnit, AddAuraGroup and SetEnabled. Each live player/party row creates one
container outside combat, fixed to that row's unit. A HARMFUL group admits all
debuff types with a maximum of eight icons and the default native ordering.
The native group provider preallocates ten CustomAuraButtonTemplate frames and
applies DenyTaintedAccessWhenAurasAreSecret after the initialization callback.
The addon initializes only size, artwork, native SetIcon, tooltip anchor and
SetCancelAuraButtons(nil). It retains no aura button references, observes no
aura state, supplies no extra templates and replaces no intrinsic handlers.

The native container owns UNIT_AURA registration, filtering, assignment, icon
visibility and flow layout. Its group applies UntrustedLayoutScriptExecution;
no addon frame is anchored to its changing bounds. The container is anchored
once to the health bar's right edge with fixed spacing reserving the drinking
indicator and, on Paladins, cleansing buttons. Icon size derives from the public
health-plus-power cluster height (19.5 logical pixels); native flow element sizes
match it, with two-pixel gaps and top alignment. Cleansing halo artwork extends
one pixel, fitting within the row gap. Native children inherit row visibility/alpha;
target rows and synthetic previews create no containers. Missing or unreadable
template metadata disables this optional display without blocking health bars.
No Lua aura scans, duration calculations, overflow counts, protected attributes
or combat layout writes are introduced. This uses the native display alone,
not the previously rejected AuraButton/SecureActionButton composition.

Mocks verify configuration/lifecycle and execute the matching exported group
setup. They cannot establish native engine permissions, tooltips, rendering or
combat acceptance. Verify acquisition/removal, roster changes, raid hiding,
preview transitions and combat on all five recipients after DEV reload.

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

## Healing editor default and resets

Healing Mouse anchors TOPLEFT to UIParent CENTER at (-270, -232), matching
Keybinds' default Mouse grid left edge and leaving ten logical pixels below it.
It neither reads sibling globals nor depends on sibling load order or visibility.
Saved editorPosition wins; reset clears the saved and transient drag overrides.
Drag coordinates retain public finite/scale guards. All positioning defers in combat.

Reset positions restores the party/target anchor, healing editor and session
minimap placement without changing bindings or buff reminders. Factory reset
uses the matching Blizzard_StaticPopup contract (OnAccept, Cancel, hideOnEscape,
whileDead and timeout=0), with a family-specific dialog identity in DEV. Acceptance
rechecks combat before replacing only this character's Heals store with fresh
validated defaults, canceling transient edits/discovery and reapplying native
bindings and learned class buff defaults. No other addon or WoW bindings change.
No automatic reset runs during upgrade. Live dialog/layout acceptance is pending.

## Left-click spell range (70009)

C_Spell.IsSpellInRange(spellIdentifier, targetUnit) returns a nullable boolean and
accepts the explicit fixed row recipient. True means in range, false out of range,
and nil invalid/unknown. Access.Read rejects secret/inaccessible results before
comparison. No distance estimate, target fallback or UnitInRange substitute is used.
EnableSpellRangeCheck/SPELL_RANGE_CHECK_UPDATE only track the current target and
cannot supply party-row updates. A 0.2-second range-only OnUpdate samples at most
five units without aura scans; it stops during preview/world exit or without an
active mapped spell/API. The cached ID is the exact successfully applied plain
left action, including learned class defaults. Deferred combat changes keep the
installed action's ID until Apply can safely update both. Only presentation alpha
and labels change in combat; no protected attributes/layout/visibility change.
Unknown, dead, offline and missing recipients clear previous range feedback.
Native range behavior and combat presentation still require live acceptance.

## Contracts used

- InputDocumentation.GetCursorPosition returns screen coordinates;
  SimpleFrame.GetEffectiveScale and SimpleScriptRegion.GetCenter supply the
  minimap-local conversion. GetCenter may return nothing or secret coordinates;
  all cursor/center/scale/dimension inputs are checked for public finite values
  before calculation. GetFrameLevel is also aspect-secret: placement defers
  unless its public finite integer permits the shared +20 level offset.
  RegisterForDrag("RightButton") activates temporary
  OnUpdate sampling. HookScript("OnSizeChanged") preserves existing map handlers.
  Placement uses a constant circular radius (half the larger dimension + 16)
  and default angle 220 minus max(15, deg(2*asin(min(1,46/(2*radius))))),
  putting Heals upper-left, Keybinds middle and Tank lower-right.
  Valid drags update only a local session angle; the
  historical minimapAngle field is preserved verbatim but never used for placement.
  Reload resets the local angle. Shared neighboring defaults use adaptive angular
  spacing with a minimum 46-pixel chord to avoid overlapping 32-pixel click boxes.
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

- Readable labels join UnitName's separate first-name and surname returns using
  CHARACTERNAME_SURNAME_SEPARATOR, matching Camelot NameUtil.FormatUnitNameForDisplay.
  The generic generated API labels the second return unitServer, but the selected
  Camelot implementation uses it as surname. Both parts must pass public-value
  guards before concatenation. Missing/empty surnames leave the first return intact;
  restricted identities stay blank. The loader TOC and Camelot NameUtil source
  are checked export inputs, and a matching-source test compares composition.

- Blizzard_Fonts_Shared/Shared/GameFonts.xml defines Number12Font, a native
  locale-aware sans-serif family used for preview-handle text. Names retain the
  original GameFontHighlightSmall font at 6 logical pixels, consistently for all units.
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

### Purify native-slot rejection (70009)

Live acceptance failed: SecureTemplates.xml:8 emitted five forbidden OnClick
replacement warnings. AuraButton's intrinsic OnClick_Intrinsic is protected by
UntrustedScriptExecution and AlwaysPropagateInput; SecureActionButtonTemplate
attempts to assign SecureActionButton_OnClick. Public template discovery and
initialization hooks do not establish composability. The warning does not throw
a Lua exception, so pcall is not a capability check for this failure.

The revised, explicitly requested UI uses permanent secure buttons with separate
native visual siblings. Each Paladin row creates ordinary SecureActionButtonTemplate
buttons anchored directly to the health bar. Each learned spell is resolved through
existing guarded player spellbook/helpful checks; Purify 1152 admits Poison/Disease,
Cleanse 4987 also admits Magic. LeftButtonUp/useOnKeyDown=false and fixed unit/spell
attributes use native dispatch. Modified left clicks are blocked. Attributes and
visibility drivers change only outside combat, on spell/world/preview changes.

A separate CustomAuraContainerTemplate holds two HARMFUL native slots with dispel
candidate filters. Their callbacks create gold halos and constant spell artwork, disable mouse
input and cancellation, and replace no scripts. They never inherit a secure-action
template. The secure buttons are neither descendants of nor anchored to native aura
frames; both hierarchies anchor independently to public row geometry. Native slot
visibility affects only the gold edge and full-color spell artwork, never button
visibility, attributes or input. The secure sibling's idle texture is permanently
desaturated at 30% alpha; native active artwork is mouse-disabled and above it,
using the same guarded public frame level. It shows the cleansing spell's public
icon, not the matched debuff's icon. No texture is read back or aura state inferred.
No restricted aura data, slot state or visibility is read back. Spellbutton frame
levels use public finite integer guards. Intrinsic forbidden script/input and
layout propagation remain intact; no restriction is removed or bypassed.

Purify and Cleanse show only if learned; both remain visible without matching auras.
A matching type does not promise removability, range, mana or cast success. Native
spell execution chooses effects, not an addon-selected aura. The new layout reserves
two spell positions before the eight-icon debuff strip on Paladins only. Mocks and
matching native filtering/release-dispatch checks cover all five fixed recipients;
actual engine permissions, visual layering, physical clicks and combat glow require
live acceptance. The old failed composition is never constructed.

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

## Bandage assignments (70009)

GameCursorDocumentation exposes GetCursorInfo; Blizzard_ArtifactPerks consumes
its item cursor as type, itemID, itemLink. ItemDocumentation.GetItemInfoInstant
returns ID, icon, class and subclass; public guards precede classification against
ItemClass.Consumable and ItemConsumableSubclass.Bandage. GetItemNameByID supplies
the optional localized display name; an uncached name uses the item ID label.
GET_ITEM_INFO_RECEIVED retries unavailable metadata outside combat (deferred to
combat exit otherwise). Saved spell numbers remain unchanged; item entries are
{kind="item", id=positiveInteger} in the existing bindings map. No bag slots,
counts, target state or restricted values are persisted.

SecureTemplates SECURE_ACTIONS.item reads the modified item attribute, resolves
item:ID through SecureCmdItemParse and calls SecureCmdUseItem with the fixed row
unit. Every out-of-combat apply clears the opposite spell/item attribute. Empty
stacks remain assigned; native inventory resolution, range, cooldowns, skill and
Recently Bandaged restrictions decide whether physical input succeeds. Item
assignments disable the spell-only range indicator. Tests execute matching native
item/release source with mocked engine functions; live acceptance is still needed.

## Fixed target frame (70009)

A separate anonymous SecureActionButtonTemplate uses immutable unit=target and
the shared native healing bindings, with [@target,exists] visibility in all group modes.
It stays outside party range polling, buff scans and party preview.
Its 112-logical-pixel row matches the player/party width and shares the existing health/power, font, rail and native
incoming-heal presentation, left-aligned above the player with a full-row
(19.5 logical pixel) gap. Both target rows retain their existing dimensions.
No target event changes protected attributes, anchors or visibility.

The selected Camelot NameUtil uses UnitName's two returns as name and surname,
despite the generic UnitDocumentation unitServer label. Target and party labels
share guarded composition, preserving NPC titles and both character-name parts.
Restricted identity remains blank; no string splitting or restricted-value
comparison occurs.
UnitIsPlayer and UnitReaction(target, player) pass through Access.Read before Lua
branching; public player class tokens use the existing class-color helper, and
public NPC reactions use friendly (5+), neutral (4), hostile (1-3) stripe colors.
Unknown/restricted classification resets the stripe to muted. Level reads retain
the guarded ? fallback. Target names remain visible in combat when readable. All unit names use
the same 6-pixel font, including player, party, preview and unknown targets. The name is
never split or shortened in Lua.
Health and power quantities stay in native display sinks. A public nonpositive
maximum power clears the fill; restricted maxima are never compared in Lua.
PLAYER_TARGET_CHANGED and target unit updates refresh identity and bars; native
visibility owns disappearance. Live rendering, combat switching and long-name
fit require in-game acceptance, separately from mocks and matching-export checks.

## Target of target (70009)

Player/party name and level labels now remain visible during combat as well.
The existing public-value guards still blank restricted names and use ? for
unavailable levels. Dead/offline/out-of-range statuses retain precedence.
Only FontString presentation changes; protected layout and actions stay unchanged.

### Selected-target cast strip (70009)

UnitCastingInfo return 10 and UnitChannelInfo return 11 are nullable, NeverSecret
castBarIDs. Guarded IDs, or a readable nonempty name when the ID is absent,
establish cast/channel presence. Restricted names and timestamps never enter
Lua comparisons or arithmetic. UnitCastingDuration/UnitChannelDuration feed
SetTimerDuration directly, with Immediate interpolation and ElapsedTime for
casts or RemainingTime for channels. SimpleStatusBarConstantsDocumentation.lua
is included in the checked export inventory. Optional API/sink failure restores
power; no timestamp-based fallback or interruptibility inference is used.

An anonymous, mouse-disabled StatusBar occupies exactly the selected target's
power strip. Alpha swaps presentation with the existing power bar; health, name,
unit/action attributes and protected layout do not change. The native timer
animates progress without Lua polling. Start/stop/delay/failure/interruption and
channel events requery current target state, so stale event identities cannot
clear a different current cast. Target changes/show and world entry refresh it;
world exit clears the presentation. Target's target keeps its power strip.
Native restricted-data acceptance, animation, event timing and combat rendering
remain live acceptance checks, separate from mock/native-source verification.

### Target-of-target behavior

The anonymous targettarget row uses fixed native healing actions and independent
[@targettarget,exists] visibility. It is positioned once above target with a
four-logical-pixel gap and no helper label. Width, colors and name sizing
match target. Top-edge position clamping
reserves space for both rows and the drag handle above them. Dragging
subtracts that full handle offset to preserve the party anchor; no combat layout writes occur.

UnitDocumentation defines synchronous UNIT_TARGET with a unit token payload.
Matching Blizzard_UnitFrame/Mainline/TargetFrame.lua refreshes its target-of-target
on UNIT_TARGET and via OnUpdate. Our target/targettarget events refresh these
rows, while a visible-only 0.2-second OnUpdate refreshes just targettarget to
cover unit-alias updates without scanning auras or running party healing logic.
World exit suspends reads; world entry resumes them. Health/power and prediction
use the existing native sinks; identity and reaction retain public-value guards.
No GUID, inferred aggro or protected visibility mutation is added. Native rendering
and combat visibility remain live checks.

## Healing actions on both target rows

Bindings.Apply now applies the same fifteen slots and modifier-blocking matrix to
player, party1-4, target and targettarget. The unit attributes remain immutable;
only action attributes are applied outside combat. Saved edits, learned class
defaults, spell ranks and item assignments share one resolution per slot. Empty
plain Left targets only if no assignment or learned default exists; unavailable
assigned spells remain no-op. Native secure spell/item actions receive the exact
row unit. No helpful/hostile target detection, retargeting or casting is done in
Lua; the client decides legality, range, cooldown and item availability at click.
Matching-export tests exercise spell/item release dispatch on all seven frames.
They do not prove native secure provenance, hostile-target rejection, taint or
physical-click behavior in game; these require live acceptance.

## Healing Mouse input feedback

The native secure recipient buttons use PostClick for cosmetic feedback only,
matching Keybinds' physical input pattern. OnClick is never replaced; no action,
unit, visibility or layout attributes change in that callback. Readable mouse
release and InputDocumentation IsAltKeyDown/IsControlKeyDown/IsShiftKeyDown values
select the existing plain/Shift/Ctrl tile; Alt, combined modifiers and unavailable
reads flash nothing. All seven fixed recipients share the same handler.

The already-open editor shows Keybinds' identical blue (0.35,0.75,1,0.4) overlay
for 0.15 seconds. A serial prevents an old timer hiding a later press. Empty or
unavailable actions also flash, indicating input rather than cast success. Direct
editor tile clicks flash without casting; drag/drop continues its existing edit
behavior. Hidden/uncreated editors stay hidden; closing clears pending visuals.
Combat retains the existing editor-close behavior. Native PostClick delivery and
visual timing still require live acceptance; mock checks do not prove taint safety.

## Settings background

Reviewed SimpleFrame CreateTexture, SimpleTextureBase SetColorTexture and
SimpleScriptRegionResizing SetAllPoints in the current export. The settings
canvas owns one BACKGROUND texture, anchored to its bounds with Essentials'
RGBA (0.035,0.035,0.045,0.96). Controls and other pages keep their alpha.
Native UI scale/contrast remains a live check.
