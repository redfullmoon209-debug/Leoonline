# LEOM Game Design — 3D farming MMORPG

Status: PRODUCT TARGET (not all features are implemented). Inspired by the genre's progression loop, not copied game content.

## Core player loop
1. Choose a hunting area appropriate to current level and risk.
2. Kill roaming monsters / world boss; earn server-confirmed EXP and currency.
3. Collect individually owned drops; send to inventory or storage; sell, trade, or upgrade.
4. Improve build, skills, equipment and profession; unlock more dangerous areas.
5. Opt into arena / guild war or take risk in open-PK fields, then return to farming.

## Character and progression
- Persistent account owns character slots; character owns class/profession, level, EXP, attributes, stats, equipped items, bag, warehouse rights, guild membership, PK record.
- Six core attribute categories should be mapped from Godot's strength, vitality, agility, intelligence, dexterity, luck.
- Level cap is **TBD after balance tests**, do not invent a cap in code.
- EXP curve, drop tables, damage formulas and profession skills are **data-driven** and server-validated.
- 6 profession lines from existing job_catalog.gd are migration candidates; preserve IDs and player-facing localized names until a deliberate revision.

## Combat and monsters
- Third-person 3D target selection, basic attack, cooldown skills, armor/resistance, movement and hit validation.
- Monster definition: stable monster ID, level, max HP, attack pattern, spawn region, respawn policy, target/aggro radius, loot table, XP and reward range.
- Spawn, despawn, aggro, combat, loot dice and achievement events are authoritative on the zone server.
- Rare and boss loot uses item IDs/quality and server-generated ownership windows; prevent duplicate pickup by transactional award.
- Drop rates, rarity names and values in the first playable demo are *illustrative*, not economy commitments.

## Inventory and economies (migrate existing constraints)
- Inventory: 200 slots total, 40 initially unlocked in Godot. Preserve the existing timed/unlock behavior or intentionally redesign it.
- Storage: 200 slots. Equipment and cosmetics as separate equip rules.
- Four currency types (gold, blue gems, purple gems, green gems); preserve *decimal strings* up to 21 digits each.
- Transactions: shops, trading, storage, crafting, upgrade. Server owns balances, ownership, and exact arithmetic.
- Item definition separates item ID, name, rarity, weight/stack limits, equip type, level/class requirements, bound/tradable status, upgrade tier.
- All operations must be atomic, idempotent, auditable; client inventory is only a UI projection.

## Zones and PvP policy (initial proposal)
| Zone type | Player damage | Entry / notes |
| --- | --- | --- |
| Safe | Forbidden | Town, newbie spawn, NPC market, storage |
| Hunting | Monster combat | Safe hunting zones; no uninvited PK |
| Open PK | Allowed outside protected contexts | Risk and flag / karma penalty |
| Arena | Only opponents in an approved match | 1v1, 3v3, 5v5; separate scoring / rewards |
| Guild War | Only eligible opposing guild members | Timed match / territory objectives |

- PK attacks require zone permission, character eligibility and server-side PvP damage checks.
- Initial PK model: active aggressor flag, kill record, optional karma penalty, cooldown to clear flag, death/respawn safety. Exact penalties and minimum level TBD.
- No attacks on allies in the same party/guild by default (guild-war exception requires explicit opposing-team rules).
- Arena has matchmaking, ready state, fixed match boundaries, disconnect policy, anti-win-trading controls, rating and season reset.
- Guild war: guild membership rights, scheduled eligibility, capture points, score, tie-breaker, reward logs and cooldowns.
- Implement tests for safe-zone bypass, invalid target, dead player, cross-instance attack, spoofed guild and duplicate rewards.

## Social and operations
- Party invites and membership; party XP/loot assignment rules still to be chosen.
- Guild creation, roles, invitations, treasury permissions and war eligibility.
- Authentication, abuse reporting, player sanctions, economy monitoring, GM/audit capability without client authority.
- Localization priority: Thai and English.

## Non-goals for the foundation
No claim of playable multiplayer, persistent server characters, production anti-cheat, browser/phone packaging, or finished UI. These are later milestones.
