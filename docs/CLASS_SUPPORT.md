# Class support on Forever

Reviewed against Forever 1.60.1.70009 on September 27, 2026. Candidates are
validated against the live learned spellbook; database presence never grants an
action. This is a pre-combat upkeep guide, not an encounter optimizer.

| Class | Left-side upkeep | Friendly cleanse buttons |
| --- | --- | --- |
| Paladin | Existing lasting blessing choices and own aura picker | Purify; Cleanse |
| Druid | Mark of the Wild; Thorns | Cure Poison; Abolish Poison; Remove Curse |
| Priest | Fortitude; Divine Spirit; Shadow Protection; self Inner Fire | Dispel Magic; Cure Disease; Abolish Disease |
| Mage | Arcane Intellect; self armor alternatives | Remove Lesser Curse |
| Shaman | Self Lightning Shield; native weapon enchantment display | Cure Poison; Cure Disease |
| Warlock | Self Demon Armor/Skin alternatives; native weapon enchantment display | Pet action not enabled; see limitation below |
| Hunter | Own aspect picker; self-activated Trueshot upkeep if learned | No general friendly-player cleanse |
| Warrior | Self-activated Battle Shout upkeep | No general friendly-player cleanse |
| Rogue | Native weapon enchantment display | No class friendly-player cleanse |

Every class retains native debuff icons. Cleanses use fixed player, party1-4
and target recipients. The selected target support gate remains friendly and
living. No new target-of-target controls. A matching-type gold indicator does
not promise range, sufficient resources, removability, or cast success.

Curated families use exact IDs, any recognized rank and any caster for coverage.
Each independent missing family remains available. Group variants (Gift, Prayers,
Brilliance) cover their corresponding ordinary families but are not offered as
new actions until recipient behavior is accepted on the client. Unknown scans
show no missing-buff claim. Recognized catalog entries do not also appear through
generic discovery. Existing saved disabled entries remain disabled across ranks.

Highest learned rank is a selection policy, not a claim of greatest measured
benefit. Mage armors and Warlock armors each form one coverage family; choices
appear only when no member is present. Self buffs, Battle Shout and Trueshot are
player-row actions, never individual party casts. Native requirements still apply,
including Battle Shout's rage cost. Buff choices hide in combat.

Yellow suggestions are guidance, while the brighter cleanse indicator means a
matching debuff type. Mark and Fortitude have broad benefits. Thorns is suggested
for an assigned tank after Mark; Spirit/Intellect guidance uses healer role then
mana-using class. Shadow Protection stays manual. Hunter Hawk is explicitly a
ranged-play fallback with unknown combat style; an assigned tank can get Monkey.
Travel aspects are never suggested for combat. An already active own aspect
suppresses the picker; another Hunter's effect does not establish own selection.

Weapon icons are native, player-only main-hand/off-hand temporary-enchantment
displays, with native inventory tooltips and durations when supported. They do
not claim that an uncoated weapon needs a specific item, and do not apply, craft,
replace or buy coatings. Native events update them; upkeep display hides in combat.

## Deliberate limits

- Felhunter Devour Magic: the native secure pet action accepts a fixed recipient,
  but uses an action-bar slot without checking expected spell identity. A verified
  combat-safe identity/visibility contract is still needed before exposing it.
- Improved Mend Pet affects the Hunter's own pet; it is not a party cleanse.
- Totems, native pet autocast, forms/stances, emergency cooldowns, conjured-item
  distribution and weapon application retain their native interfaces. They do not
  become generic recipient upkeep buttons.
- Additional racial/situational effects and group-cast choices need matching-client
  aura/recipient confirmation. This update does not claim exhaustive spell support.

## Evidence

Matching-build extracted spellbooks: [Druid](https://www.60.tools/spellbook/druid),
[Priest](https://www.60.tools/spellbook/priest), [Mage](https://www.60.tools/spellbook/mage),
[Shaman](https://www.60.tools/spellbook/shaman), [Warlock](https://www.60.tools/spellbook/warlock),
[Hunter](https://www.60.tools/spellbook/hunter), [Warrior](https://www.60.tools/spellbook/warrior),
and [Rogue](https://www.60.tools/spellbook/rogue). Hunter's changed Trueshot rank
chain is described in the [build-specific changes](https://www.60.tools/changes/hunter).
These are extracted client records, not live server acceptance.

The local matching Blizzard export verifies native filtering, stance queries,
fixed-recipient spell/pet dispatch, and player-owned enchantment containers. See
API_REFERENCE.md and wow-api-export.json. Source and packaged mocks exercise
these contracts but cannot prove secure input provenance or rendered behavior.

## Live acceptance

For each available class, check learned/unlearned ranks, each upkeep family,
other-caster coverage, one physical cast per click, native tooltips, dim/bright
cleanse artwork, simultaneous matching types, and all six fixed recipients.
Switch friendly/hostile/dead targets in and out of combat. Check no protected
mutation/taint warning, no stale suggestions after zoning/preview, and correct
recovery on combat exit. Verify native Hunter aspect state, Warrior rage failure,
Druid/Priest form restrictions, and weapon swaps/expiration independently.
New Lua files and a changed TOC require client discovery after reload; restart
only if the client does not discover them. Installation is not live acceptance.
