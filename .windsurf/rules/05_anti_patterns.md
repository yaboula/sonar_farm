---
trigger: always_on
---

# Technical Anti-patterns (always-on, refuse to write)

These are forbidden in Farm Sonar code. If a sub-agent suggests one, refuse and propose the correct pattern.

## 1. Direct calls between resources

**Forbidden:**
```lua
exports['some_other_resource']:DoThing()
```

**Correct:** publish/subscribe via the FiveM event bus with `sonar:farm:*` namespace, OR via the bridge layer for framework methods.

## 2. Client-authoritative game state

**Forbidden:** trusting the client for any value that affects gameplay (money, inventory, plot state, batch quality).

**Correct:** server is the single source of truth. Client only renders. Every mutation flows through a server validation.

## 3. Hardcoded values in code

**Forbidden:** prices, durations, NPK ranges, IBAN prefixes, animation timings, weights, capacities — anything tunable — written inline in code.

**Correct:** all in `config.lua` or `config/<domain>.lua`. Per-crop values in `config/crops/<crop>.lua`.

## 4. Polling per-frame for stage transitions

**Forbidden:**
```lua
CreateThread(function()
  while true do
    Wait(0)
    -- check if any plot needs to advance
  end
end)
```

**Correct:** scheduler that ticks every N seconds (configurable, default 30s) and queries only plots whose `next_stage_ts <= now()`.

## 5. Synchronous DB reads in hot paths

**Forbidden:** blocking on `MySQL.Sync.fetchAll` inside event handlers that fire frequently.

**Correct:** async via `oxmysql:query` with callbacks/awaits. Cache hot data in-memory with TTL.

## 6. Forgetting to publish events on state changes

**Forbidden:** mutating DB without publishing the corresponding `sonar:farm:*` event.

**Correct:** every state-changing service method ends with `TriggerEvent('sonar:farm:<domain>:<action>', payload)` so other domains can react.

## 7. Tight coupling to QBox-only or QBCore-only APIs

**Forbidden:** `QBCore.Functions.GetPlayer(src):PlayerData.money.bank`.

**Correct:** `Bridge.GetPlayer(src):GetMoney('bank')`. Always go through the bridge.

## 8. Lineage chain mutation

**Forbidden:** modifying or losing `lineage_chain` when transferring a batch between inventories or processes.

**Correct:** lineage is append-only. When a batch is transformed (e.g. wheat → flour in a future vertical), the new batch's `lineage_chain` includes the old `batch_id`.

## 9. Blocking the player thread on long animations without escape

**Forbidden:** `TaskPlayAnim` for 30+ seconds with no cancel option.

**Correct:** progress bar via `ox_lib`'s `lib.progressBar` with cancelable flag, OR break the animation into chunks with checkpoints.

## 10. Logging player money/IBANs at INFO level

**Forbidden:** PII or financial data in default-level logs (privacy + audit risk).

**Correct:** financial events go to a separate audit table (`sonar_farm_bank_movements`) which IS the log. INFO logs reference movement IDs, not amounts.
