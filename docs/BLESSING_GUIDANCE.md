# Beginner blessing guidance

Reviewed September 27, 2026 for Forever build 1.60.1.70009.

The yellow border is a conservative starting suggestion for pre-combat party
upkeep, not an optimal raid assignment or a claim of an 80% success rate. It
selects one currently offered, learned blessing and leaves every alternative
available. A tooltip explains the benefit and whether role or class informed it.
The recommendation does not infer talents, gear, threat, mana urgency or intent.

## Research findings

The matching-build [60.tools Paladin spellbook](https://www.60.tools/spellbook/paladin)
shows Might increasing **melee** attack power, Wisdom restoring mana, and Greater
blessings affecting same-class group members. That rules out treating every
physical damage dealer as a Might recipient: a hunter's combat style is unknown.
It also supports preferring the ordinary variant for a recommendation attached
to one specific recipient. These are data-informed design decisions, not a
published universal priority list. This database separately marks Sanctuary as
absent from the current Forever spellbook; existing addon candidates remain
runtime-gated by learned-spell validation, so a candidate is never a spell grant.

[Wowhead's Forever ability guide](https://www.wowhead.com/forever/guide/classes/paladin/holy/healer-abilities)
confirms Kings' broad stat benefit, Wisdom's mana regeneration, Light's benefit
to Holy Light/Flash of Light, and Salvation's threat reduction. These effects
support an approachable first choice but do not identify the best choice for
individual gear or encounters. Salvation remains manual: threat-limited damage
dealers can prefer it, but the addon does not establish that condition. Light
and Sanctuary are also manual, rather than universal fallbacks.

The [Classic class overview](https://www.wowhead.com/classic/guide/classes/paladin/overview-basics)
lists Wisdom/Kings among healer options and Might among melee options; it also
places Salvation prominently for damage dealers. Classic priorities are context,
not assumed Forever rules. [Warcraft Tavern's Classic blessings discussion](https://www.warcrafttavern.com/wow-classic/guides/understanding-the-paladins-blessings-part-1-the-most-important-raid-blessings-classic-wow/)
discusses using Light on a tank with a Paladin healer. This illustrates why
reasonable players disagree on a universal tank blessing. We use Kings for broad
benefit and preserve manual choice instead of optimizing healing or threat.
Expansion-mismatched forum advice and numerical tuning are not used as rules.

## Implemented decision order

Assigned TANK and HEALER take precedence over class. DAMAGER still needs class
to distinguish melee from caster; it cannot reveal a hybrid's specialization.
Missing, NONE, failed or restricted role reads fall back to a public class.

| Recipient information | First choice, then learned fallback |
| --- | --- |
| Tank: Warrior or Druid | Kings, Might |
| Tank: Paladin | Kings, Wisdom |
| Tank: other/unknown class | Kings |
| Healer | Wisdom, Kings |
| Warrior or Rogue; Paladin assigned damage | Might, Kings |
| Mage, Priest, Warlock without a tank/healer override | Wisdom, Kings |
| Hunter | Kings, Wisdom |
| Paladin, Druid or Shaman with ambiguous specialization | Kings, Wisdom |
| Neither usable role nor recognizable class | Kings |

This table is our conservative heuristic, inferred from the effects and common
roles, not copied from a guide or presented as best-in-slot advice. A hybrid's
fallback may be suboptimal. When none of the suitable options is learned,
no border is shown; we never fall through to Salvation or an emergency spell.
Within a family the ordinary version is preferred if offered, otherwise the
learned Greater version may be suggested. Existing highest-rank validation is
unchanged. No bag/reagent check or automatic spell execution is added.

## API and acceptance

The local UnitDocumentation marks UnitGroupRolesAssigned as potentially secret;
Access.Read validates before comparisons. UnitClass's token has the same guard.
The matching CompactUnitFrame source refreshes on PLAYER_ROLES_ASSIGNED. The
addon handles that event through its existing out-of-combat refresh, alongside
roster/spell/aura changes. The steady one-pixel yellow border is display artwork;
secure actions and fixed recipients remain unchanged. Native spell tooltips gain
one plain-language recommendation line. Combat and lifecycle cleanup remove the
suggestion. Source and packaged mocks must pass; visual appearance, role delivery
and physical clicks still require in-game acceptance.
