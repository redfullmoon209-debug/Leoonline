# LEOM implementation roadmap and acceptance criteria

This is the staged backlog for a full Unity 3D MMORPG. Each milestone is gated; no calendar or delivery date is promised.

## M0 — Repository and Unity bootstrap [IN PROGRESS]
- [x] Preserve original Godot repository at root.
- [x] Choose Unity 6.3 LTS and add independent project under unity/.
- [x] Document gameplay scope: farm / EXP / PK / arena / guild war / dedicated server.
- [x] Add source for an Editor menu that generates a primitive 3D offline prototype.
- [ ] Open/import project in an installed Unity Editor; confirm no compile errors.
- [ ] Generate first .unity scene and commit its serialized assets/meta files after visual QA.
- [ ] Windows (and target device) hands-on playtest.

## M1 — Offline PvE vertical slice
- [x] Third-person prototype player controller, camera, monster AI, melee hit, XP, loot and bag demonstrator in source.
- [ ] Validate in Unity Play Mode on Windows; fix collisions, UI, gameplay and persistence.
- [ ] Integrate exact FemaleLeo mesh and animation clips with rig/bone check.
- [ ] Import approved map meshes and texture palette; build accurate terrain/building colliders.
- [ ] Implement real skill animation events, target selection, hit FX and tutorial.
- [ ] Add deterministic unit tests for EXP thresholds, loot capacity, exact 21-digit currency math.

Acceptance: a tester can open the Unity scene, fight five monsters, level up, collect and save loot without exceptions. No misleading online indication.

## M2 — RPG data migration
- [ ] Stable item/skill/job IDs and localized text database with compatibility snapshots.
- [ ] Actual 200-slot inventory (40 unlocked), equipment, 200-slot warehouse.
- [ ] Four separate currencies, atomic server-ready commerce APIs, 21-digit string encoding.
- [ ] NPC shops, upgrade tiers, rarity data, loss/gain probabilities and anti-duplication invariants.
- [ ] UI for inventory, character, skill, shop, minimap, storage on desktop and phones.
- [ ] World bosses, party UI and balanced drop tables.

Acceptance: migration tests prove slot/currency conservation and no item duplication.

## M3 — First authoritative multiplayer
- [ ] Select networking stack from measured NGO/Entities spike.
- [ ] Dedicated zone server (not client host), 2-player login, authenticated sessions.
- [ ] Server movements, attack validation, monster simulation, EXP, loot and inventory state.
- [ ] SQL persistence with unique item IDs, audit log, idempotent inventory requests.
- [ ] Reconnect and lag/packet-loss simulator.
- [ ] Rate limits, malicious-client test suite, developer permissions on server.

Acceptance: two remote accounts see the same monster; simultaneous kill/pickup cannot duplicate any item; forging a client currency or damage message does not work.

## M4 — PK / arena / guild wars
- [ ] Safe zone, hunting zone, open PK, arena and guild war permissions enforced on server.
- [ ] PK flag and penalty rules approved; spawn protection, minimum level, party/guild team rules.
- [ ] Arena queue 1v1/3v3/5v5, matchmaking, winner, anti-farm, rating and seasonal rewards.
- [ ] Guild roles/permissions/treasury, map objectives, war scheduling, score and settlement.
- [ ] Leaderboards and disciplinary/audit workflow.

Acceptance: protected zone denies all PvP, arena awards once, guild spoofing and score injection fail.

## M5 — Alpha/live operations
- [ ] Profile player/monster capacity per zone, interest management, instance transition.
- [ ] Anti-cheat analytics, backup/restore testing, rollbacks and economy monitoring.
- [ ] Accessibility, Thai/English locale, graphic settings, device compatibility.
- [ ] Closed alpha, telemetry, balance pass, crash reporting and deployment runbook.

## Open product decisions
- Art style/visual quality target and minimum supported PC/phone spec.
- Level cap, progression curve, exact items/drop rates, leveling speed.
- Details of PK penalties, death item losses (if any), PvP minimum level.
- Region/shard and expected simultaneous users.
- Monetization and account policy.

Scope discipline: complete the offline playable loop, then data invariants, then real multiplayer, then mass PvP. Never claim a local prototype is a networked MMORPG.
