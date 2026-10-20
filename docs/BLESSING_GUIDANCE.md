# Five-player blessing guidance

Reviewed October 20, 2026. Local API authority remains the verified Forever
1.60.1.70450 / 16001 export. Spell candidates must resolve through the actual
learned/helpful/active spellbook. The yellow border is a practical dungeon default,
not a measured popularity ranking, gear optimizer or inferred specialization.

## Evidence and limits

[Blizzard's October 15 Paladin deep dive](https://worldofwarcraft.blizzard.com/en-us/news/24302099)
confirms that Salvation is no longer a blessing and can coexist with one. It must
not be a competing default in the Might/Wisdom/Kings indicator. This change does
not add new Salvation/Revoke actions; old candidate spell IDs remain gated by the
native spellbook. Short/emergency spells never become a fallback suggestion.

The [Forever: Pally Blessings Assignment author's documentation](https://www.curseforge.com/wow/addons/forever-blessings)
uses Might then Kings as its Protection Warrior priority example and Wisdom then
Kings for Holy Priest. Its separate dungeon Salvation controls reinforce treating
threat reduction separately. This is one practitioner's design, not usage telemetry.

[Forever player discussion](https://www.reddit.com/r/wowforever/comments/1x6ujis/paladin_class_deep_dive_in_wow_forever/)
describes Protection Paladin mana pressure and using Wisdom with Seal of Fury.
Wisdom remains a mana-sustain option, but this does not establish it as the usual
first choice. Forever adds mana recovery through Improved Seal of Fury and Shield
Specialization. The [EzBlessings author's priorities](https://www.curseforge.com/wow/addons/ezblessings)
put Kings before Wisdom for Paladin tanks. The owner selected Kings first with
Wisdom as the learned fallback; this is a default, not a population-wide trend.

The [60.tools extracted Paladin spellbook](https://www.60.tools/spellbook/paladin)
currently labels its spell data 70425, rather than the local 70450 API export.
It is contextual spell-effect evidence only, not replacement API authority:
Might affects melee attack power, Wisdom restores mana, Kings affects stats, and
Greater variants affect same-class group members. We therefore use Wisdom for
the usual ranged Hunter rather than assuming Might improves ranged damage.
The addon cannot identify melee Hunter intent or Feral/Balance and Enhancement/
Elemental from assigned DAMAGER alone. It must not claim those specializations.

## Implemented order

Assigned TANK and HEALER take precedence. Missing, NONE, failed or restricted
roles fall back to a public class. Every fallback must itself be learned.

| Recipient | First choice, then fallback |
| --- | --- |
| Warrior tank | Might, Kings |
| Paladin tank | Kings, Wisdom, Might |
| Druid tank | Kings, Might |
| Other/unknown tank class | Kings |
| Any assigned healer | Wisdom, Kings |
| Warrior/Rogue | Might, Kings |
| Paladin assigned damage | Might, Kings, Wisdom |
| Mage/Priest/Warlock | Wisdom, Kings |
| Hunter | Wisdom, Kings |
| Druid/Shaman damage or unknown spec | Kings, Wisdom |
| Unassigned Paladin | Kings, Wisdom, Might |
| Unreadable/unknown class and role | Kings |

The caster, melee and mana-sustain choices follow common dungeon use; the exact
fallback table is our design inference. Light can help a Paladin healer and
other options can suit particular fights, but role/class alone cannot establish
those conditions. They stay explicit choices instead of universal defaults.

Leveling Paladins can fall back to Might before learning Wisdom or Kings, except
when assigned healer. Damage Paladins can use Wisdom when neither Might nor Kings
is available. These last-resort choices do not change the preferred blessing.
Training or losing a spell refreshes the indicator; changes during combat wait
until combat ends. Each ordinary/Greater variant uses its highest learned rank.

Ordinary ranks are preferred for an individual row; a learned Greater variant
is the fallback within its family. The indicator selects at most one offered
choice and explains the reason in the tooltip. No suitable learned choice means
no yellow border. Existing blessing coverage suppresses automatic prompts;
expansion still protects the same type from another/unknown caster. Manual and
Off preferences retain their Smart buffs semantics. No automated casts occur.

## Validation

Role/class matrix tests cover all nine classes, learned ordinary/Greater
fallbacks, unknown/restricted roles, indicator/tooltips, role transitions,
combat hiding and fresh restoration. Existing foreign-caster, range, early
refresh and lifecycle tests remain. Generated PROD/DEV checks use the same
owning tests. Native visual appearance, role delivery and physical casting
still require owner testing after approved DEV installation.
