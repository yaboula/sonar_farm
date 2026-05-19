# `Sonar.Farm.Finance` — Public Interface

> **Stability:** S3 baseline contract.
> **Authoritative decisions:** Bible §2.3, §3, §8.1, §9.2; ADR-005; ADR-008.
> **Scope:** Farm-local finance compatibility layer and audit ledger. Not a mandatory bank replacement.

Farm Sonar reads and mutates money only through `Sonar.Farm.Finance`. The S3 baseline adapter is `native_bridge`, which delegates to `Sonar.Farm.Bridge.GetMoney`, `AddMoney` and `RemoveMoney`.

External bank resources are not required dependencies. Future integrations must be optional adapters and must not bypass this contract.

---

## Public methods

### `Sonar.Farm.Finance.Init()`

Selects the active adapter and emits `sonar:farm:banca:adapter_selected`.

### `Sonar.Farm.Finance.GetActiveAdapter()`

```lua
---@return table adapter_info { adapter_name = string, mode = string }
```

Returns the selected adapter. S3 baseline returns `native_bridge` with mode `bridge` when no config override exists.

### `Sonar.Farm.Finance.GetBalance(src, account)`

```lua
---@param src number
---@param account "cash"|"bank"
---@return number|nil balance
---@return string|nil error_code
```

Reads the current framework balance through the active adapter.

### `Sonar.Farm.Finance.CanAfford(src, account, amount)`

```lua
---@param src number
---@param account "cash"|"bank"
---@param amount number Positive integer.
---@return boolean ok
---@return string|nil error_code
```

Returns `true` only when the current balance is greater than or equal to `amount`.

### `Sonar.Farm.Finance.Credit(src, account, amount, reason, idempotency_key, metadata)`

```lua
---@param src number
---@param account "cash"|"bank"
---@param amount number Positive integer.
---@param reason string Required audit reason.
---@param idempotency_key string Required stable key for the logical operation.
---@param metadata table|string|nil Optional Farm domain metadata.
---@return boolean ok
---@return table result
```

Credits money through the active adapter. On first success it creates a `pending` movement row, mutates money, marks the movement `completed`, and emits `sonar:farm:banca:movement_created`.

Replaying the same `idempotency_key` with the same fingerprint returns the existing movement result without mutating money again.

### `Sonar.Farm.Finance.Debit(src, account, amount, reason, idempotency_key, metadata)`

```lua
---@param src number
---@param account "cash"|"bank"
---@param amount number Positive integer.
---@param reason string Required audit reason.
---@param idempotency_key string Required stable key for the logical operation.
---@param metadata table|string|nil Optional Farm domain metadata.
---@return boolean ok
---@return table result
```

Validates affordability before creating the movement row. An overdraw attempt returns `INSUFFICIENT_FUNDS` and does not create a successful movement.

### `Sonar.Farm.Finance.Transfer(...)`

Present in the public table but returns `ADAPTER_UNAVAILABLE` in S3 baseline. Native Bridge only exposes single-player account debit/credit primitives, so production transfer semantics are deferred until a later slice defines atomic multi-leg behavior.

---

## Adapter contract

Adapters live under `Sonar.Farm.Finance.Adapters.<name>`.

```lua
adapter.name = 'native_bridge'
adapter.mode = 'bridge'

adapter.GetBalance(src, account) -> ok, balance, error_code
adapter.Credit(src, account, amount, reason) -> ok, error_code
adapter.Debit(src, account, amount, reason) -> ok, error_code
```

Baseline adapter rules:

- `native_bridge` may only call `Sonar.Farm.Bridge.GetMoney`, `Sonar.Farm.Bridge.AddMoney`, and `Sonar.Farm.Bridge.RemoveMoney`.
- It must not call QBox, QBCore or any bank resource directly.
- External adapters may be added later only when their APIs are verified and config-gated.

---

## Error codes

| Code                      | Meaning                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `INVALID_SOURCE`          | `src` is not a valid online player source or the player has no loaded Bridge POJO. |
| `INVALID_ACCOUNT`         | Account is not `cash` or `bank`.                                                   |
| `INVALID_AMOUNT`          | Amount is not a positive integer.                                                  |
| `MISSING_REASON`          | Audit reason is empty or missing.                                                  |
| `MISSING_IDEMPOTENCY_KEY` | Mutation request has no idempotency key.                                           |
| `ADAPTER_UNAVAILABLE`     | Active adapter or required dependency is unavailable.                              |
| `INSUFFICIENT_FUNDS`      | Debit request exceeds current balance.                                             |
| `IDEMPOTENCY_REPLAY`      | Same idempotency key and fingerprint already exists; no new mutation performed.    |
| `IDEMPOTENCY_CONFLICT`    | Same idempotency key was reused with a different request fingerprint.              |
| `MUTATION_FAILED`         | Adapter rejected the money mutation.                                               |
| `DB_ERROR`                | Farm DB wrapper or migration schema is unavailable/failing.                        |

---

## Events emitted

### `sonar:farm:banca:adapter_selected`

```lua
{
    adapter_name = 'native_bridge',
    mode = 'bridge',
    reason = 'configured' | 'fallback'
}
```

### `sonar:farm:banca:movement_created`

```lua
{
    movement_id = string,
    citizen_id = string,
    direction = 'credit' | 'debit',
    amount = number,
    account = 'cash' | 'bank',
    reason = string,
    adapter_name = string,
    status = 'completed'
}
```

---

## Schema summary

S3 Backend uses one table:

- `sonar_farm_finance_movements` — logical movement ledger plus idempotency reservation.

Important columns:

- `movement_id` — deterministic Farm movement id.
- `idempotency_key` — unique logical operation key.
- `request_fingerprint` — stable canonical mutation inputs for conflict detection.
- `citizen_id`, `src`, `direction`, `account`, `amount`, `reason`, `adapter_name`.
- `status` — `pending`, `completed`, or `failed`.
- `error_code` — set on failed mutations.
- `metadata_json` — optional Farm-domain metadata for sale/contract references.

The S2 smoke table is not dropped by Backend S3 because the current migrator applies each migration file as one SQL query. Dropping it safely should be handled by Integration/DB tooling once multi-statement migrations are explicitly supported.

Movement rows are never deleted or overwritten with a different logical operation. A new row starts as `pending`, then only its status is finalized to `completed` or `failed`.

---

## Future escrow note

Escrow is out of S3 production scope per ADR-008 and the S3 mini-brief. Future contract slices may add an escrow FSM behind this same finance namespace, but must not make any external bank resource mandatory.
