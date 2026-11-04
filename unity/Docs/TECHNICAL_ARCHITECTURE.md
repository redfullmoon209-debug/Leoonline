# LEOONLINE Technical Architecture / server authority

This document specifies the intended online design, **not existing deployed infrastructure**.

## Roles
- Unity **client**: renders the world, predicts presentation/movement where appropriate, collects player intentions, draws HUD.
- **Gateway / authentication**: login, session issuance, reconnect token and rate limits.
- **World or zone server (dedicated, authoritative)**: movement limits, spawn/AI, skills, combat, EXP, loot rights, PK legality, arena and guild-war match state.
- **Persistence / game data service**: characters, 200-slot bag and 200-slot storage, exact four-currency balances, item ownership, guilds, trading transaction logs, bans and audit trails.
- **Database / cache**: relational transactional storage (e.g. PostgreSQL) and an optional ephemeral cache; these are candidate technologies, not installed here.

## World split and scale
- Start with one zone instance and a small target concurrency, load-test and measure.
- Introduce area-of-interest interest management: clients receive only nearby monsters, players and items.
- Scale using **zone instances/shards**, matchmaking instances for Arena and separate scheduled Guild War sessions.
- Seamless travel and cross-zone chat/trade are later features; do not promise one limitless shared world.
- Estimate concurrency only after measured CPU/network/profiling data.

## Networking framework choice
- Evaluate Unity Netcode for GameObjects (NGO) for the first small authoritative multiplayer slice; suitable for GameObject-based prototypes.
- Before many-hundreds-per-zone scale, evaluate Netcode for Entities or a custom dedicated simulation with a stable protocol boundary. Framework selection needs benchmarks.
- Dedicated server is preferable to player-hosted authority for inventory, rewards, PvP and economies.
- The **offline demo scripts in Runtime/Prototype are a disposable sandbox**, not server code to expose over RPCs.

## Client-to-server commands (intent, not results)
| Command | Inputs | Server validation |
| --- | --- | --- |
| MoveIntent | Tick, direction, desired action | Movement speed, collision, teleport abuse, sequencing |
| AttackIntent | Target entity ID, skill ID, input tick | Zone rights, line-of-sight, range, cooldown, weapon/stamina, victim eligibility |
| PickUpIntent | Spawned drop instance ID | Range, ownership, lifetime, available slot, concurrency |
| InventoryMoveIntent | Source and destination slot, item instance ID | Ownership, slot locks, capacity, trade lock |
| ShopBuyIntent | Shop ID, listing ID, quantity, request ID | Exact cost, existence, capacity, server price and balance |
| DuelQueueIntent | Match queue, party | Match rules and eligibility |
| GuildWarActionIntent | Match ID, objective | Membership, team eligibility, distance, match state |

**Never accept** client-provided computed damage, currency gain, loot rarity roll, EXP, item count or guild score.

## Server events
- Snapshot/Delta: identity, position, HP, status, monster state, dropped item visible state.
- CombatResult: server damage, source, target, status, server tick.
- LootAwarded / InventoryCommitted: committed item instance and updated version.
- ExperienceCommitted: level and EXP, monotonic character version.
- PKStatusChanged, MatchStarted/Ended, GuildWarScoreChanged.

## Persistence and consistency
- Characters table keyed by immutable character UUID and account UUID; unique item-instance IDs for equipment.
- Item inventory/storage positions with unique (owner, container, slot) constraint, and transaction journal.
- Monetary amounts stored as exact decimal (NUMERIC(21,0)) or validated decimal string, never float.
- Mutating RPCs carry request IDs/idempotency keys; use transactions or compare-and-swap inventory revisions to defeat repeated packets.
- All authoritative state changes must be authenticated and logged with reason, source and tick/transaction ID.
- Restore after reconnect from server snapshots, never from local client save file.

## Security and operational tests
- Replayed purchase/pickup, duplicated trade, negative amount, 22-digit overflow, simultaneous slot move, tampered position, impossible DPS, fake skill cooldown, zone boundary bypass, PK kill in safe zone, fabricated arena/guild event.
- Automated simulations: two clients attack same monster; simultaneous loot pick; disconnect during trade; zone transfer and rollback; season-end rewards applied once.
- Monitoring: transaction failures, account inventories, item creation/destruction rates, server tick time, connection spikes, packet loss, PvP anomaly alerts.

## Repository approach
- Root folder remains Godot 4.4.1 until migration is explicitly accepted.
- New Unity project is in unity/. Commit scenes and *.meta when generated. Exclude Library/Temp/Obj and generated builds.
- Use a protected review/PR process before merging Unity migration into main.
