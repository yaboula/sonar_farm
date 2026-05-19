# `Sonar.Farm.Bridge` — Public Interface

> **Stability:** stable since S1.
> **Authoritative spec:** ADR-005 (`docs/02_DECISIONS.md`).
> **Audience:** every Lua script in `sonar_farm_core` and `sonar_farm_tablet` that needs to access the player or mutate framework state.

This file is the **single source of truth** for the bridge contract. Any deviation in implementation is a bug.

---

## 1. Detection

The bridge auto-detects the active framework on first access. Resolution order:

1. Read convar `sonar:framework`. Default value: `"auto"`.
2. If convar is `"qbox"` → force `qbox.lua` adapter.
3. If convar is `"qbcore"` → force `qbcore.lua` adapter.
4. If convar is `"auto"` → check `exports.qbx_core` (truthy → qbox) then `exports['qb-core']` (truthy → qbcore). First match wins.
5. If nothing matches → load `_unsupported.lua` adapter, log:

   ```
   [sonar_farm_core][ERROR] Farm Sonar requires QBox or QBCore. ESX bridge planned for wave 2+.
   ```

   All public methods become no-ops returning `nil` / `false` so callers don't crash.

When detection succeeds, log:

```
[sonar_farm_core] Bridge initialized → framework: <qbox|qbcore>
```

### Override example (server.cfg)

```cfg
# Force QBCore even if QBox is also installed (rare).
setr sonar:framework qbcore
```

---

## 2. The `Player` POJO

Returned by `GetPlayer(src)`. **Frozen snapshot** — re-call `GetPlayer` to refresh.

```lua
---@class Sonar.Farm.Bridge.Player
---@field src         number    Player source (FiveM net ID).
---@field citizen_id  string    Canonical persistent identifier.
---@field name        string    "FirstName LastName" combined.
---@field job_name    string    e.g. "farmer".
---@field job_grade   number    0..N, framework-defined.
---@field cash        number    Current cash balance.
---@field bank        number    Current bank balance.
---@field framework   string    "qbox" | "qbcore". INFO ONLY — never branch on this.
```

### Mutability

The POJO is **read-only**. To mutate state, call `AddMoney` / `RemoveMoney` and re-fetch. Anti-pattern §2 (Bible §9.4) is enforced here: never trust a stale POJO for write decisions.

### `nil` semantics

- `GetPlayer(0)` → `nil` (source `0` is the console, not a player).
- `GetPlayer(src)` for an offline / disconnected player → `nil`.
- `GetPlayer(src)` for an existing online player without a loaded character → `nil`.
- Callers MUST handle `nil` defensively. The bridge guarantees `nil` instead of throwing.

---

## 3. Public methods (S1 baseline — 5 methods)

### `Sonar.Farm.Bridge.GetPlayer(src)`

```lua
---@param src number FiveM player source.
---@return Sonar.Farm.Bridge.Player|nil
```

Returns the frozen POJO described in §2 or `nil`. Always safe to call (no-op on `_unsupported`).

### `Sonar.Farm.Bridge.AddMoney(src, account, amount, reason)`

```lua
---@param src     number   FiveM player source.
---@param account string   "cash" | "bank".
---@param amount  number   Positive integer. Negative or zero amounts are rejected.
---@param reason  string   Short human-readable reason. Required for audit trail (S3).
---@return boolean ok      true if the framework accepted the mutation.
---@return string|nil err  Error message when ok=false.
```

The active framework or configured finance adapter is the immediate ledger. S3 must not make `sonar_bank` or any external bank resource a hard dependency; compatibility is added through explicit adapters.

### `Sonar.Farm.Bridge.RemoveMoney(src, account, amount, reason)`

```lua
---@param src     number
---@param account "cash"|"bank"
---@param amount  number   Positive integer.
---@param reason  string
---@return boolean ok      false when the player has insufficient funds.
---@return string|nil err
```

**Server-authoritative**: the bridge MUST verify `GetMoney(src, account) >= amount` before delegating to the framework. Never trust the framework's silent-failure mode.

### `Sonar.Farm.Bridge.GetMoney(src, account)`

```lua
---@param src     number
---@param account "cash"|"bank"
---@return number balance Returns 0 when player not found.
```

### `Sonar.Farm.Bridge.Notify(src, message, type)`

```lua
---@param src     number
---@param message string  Already-localized message (caller is responsible for `locale(...)`).
---@param type    "success"|"error"|"info"|"warning"
---@return nil
```

The bridge maps `type` to the framework's notification API. On QBox uses `lib.notify` via ox_lib. On QBCore uses `QBCore.Functions.Notify` with type translation.

---

## 4. Forbidden patterns (enforced by `selene` + `eslint` + code review)

- **NEVER** access `QBCore.Functions.GetPlayer(...)` or `exports.qbx_core:GetPlayer(...)` directly outside the bridge files. Use `Sonar.Farm.Bridge.GetPlayer(src)`.
- **NEVER** mutate `Player.cash` or `Player.bank` on the POJO and expect the framework to update. The POJO is frozen.
- **NEVER** branch on `Player.framework`. If you find yourself writing `if player.framework == 'qbox' then ...`, the missing abstraction belongs IN the bridge.

---

## 5. Extending the bridge

When a future slice (S2+) needs a method not listed in §3:

1. Add the method specification HERE first (PR-driven contract).
2. Add a mini-ADR in `docs/02_DECISIONS.md` justifying scope and signature.
3. Implement in BOTH `qbox.lua` AND `qbcore.lua`. Never one without the other.
4. Add a test for both adapters.
5. Update the slice mini-brief deliverables list.

The 5-method baseline is **intentionally minimal** (ADR-005 §Decisión 4). Growth is just-in-time, never speculative.
