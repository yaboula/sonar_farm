-- ============================================================
-- Farm Sonar — PhysicalItem factory specs (S7).
-- ============================================================
--
-- Plain Lua spec (no busted/luaunit). Run with:
--     lua sonar_farm_core/tests/server/physical_item_spec.lua
--
-- Coverage matrix (4 cases) per B1 QA:
--   1. CreateBatch with valid params (no batch_id provided)
--      returns a batch_id starting with "sf-" and metadata with
--      lineage_chain = {} on first harvest.
--   2. ValidateMetadata rejects payloads with a missing batch_id.
--   3. ValidateMetadata rejects payloads with freshness = 150
--      (out of 0-100 range).
--   4. ValidateMetadata rejects payloads with an invalid grade
--      ("X" is not S/A/B/C/D).
--
-- Sanity assertions (existing, kept):
--   - CreateBatch with a deterministic batch_id round-trips
--     through the metadata builder.
--   - The deterministic happy-path metadata passes
--     ValidateMetadata.
-- ============================================================

Sonar = { Farm = {} }

local inserted_batches = {}
Sonar.Farm.DB = {
    scalar = function()
        return nil
    end,
    execute = function(query, params)
        inserted_batches[#inserted_batches + 1] = {
            query = query,
            params = params,
        }
        return true
    end,
}

dofile('sonar_farm_core/server/items/physical_item.lua')

local PhysicalItem = Sonar.Farm.PhysicalItem

-- ------------------------------------------------------------
-- Sanity: CreateBatch with an explicit batch_id round-trips.
-- ------------------------------------------------------------
local batch_id, metadata = PhysicalItem.CreateBatch({
    plot_id = 'mlo_field_extensive_01',
    crop_id = 1,
    player_cid = 'citizen-1',
    crop_type = 'wheat',
    quality = 'B',
    quality_score = 76,
    weight_g = 2500,
    freshness = 100,
    lineage_chain = {},
    harvested_ts = 1000,
    batch_id = 'sf-a1b2c3d4',
})

assert(batch_id == 'sf-a1b2c3d4', 'expected deterministic batch_id')
assert(type(metadata) == 'table', 'expected metadata table')
assert(metadata.batch_id == batch_id, 'metadata batch_id mismatch')
assert(metadata.crop_type == 'wheat', 'metadata crop_type mismatch')
assert(metadata.weight_g == 2500, 'metadata weight mismatch')
assert(metadata.quality == 'B', 'metadata quality mismatch')
assert(metadata.freshness == 100, 'metadata freshness mismatch')
assert(metadata.origin.plot_id == 'mlo_field_extensive_01', 'metadata origin plot mismatch')
assert(metadata.origin.player_cid == 'citizen-1', 'metadata origin player mismatch')
assert(#metadata.lineage_chain == 0, 'first harvest lineage_chain must be empty')
assert(#inserted_batches == 1, 'expected one persisted batch')

local ok, err = PhysicalItem.ValidateMetadata(metadata)
assert(ok, tostring(err))

-- ------------------------------------------------------------
-- Case 1: CreateBatch with valid params (no batch_id provided)
-- returns an auto-generated id matching ^sf-%x%x%x%x%x%x%x%x$
-- and lineage_chain = {} on first harvest.
-- ------------------------------------------------------------
math.randomseed(1)
local auto_id, auto_metadata = PhysicalItem.CreateBatch({
    plot_id = 'mlo_field_extensive_02',
    crop_id = 2,
    player_cid = 'citizen-2',
    crop_type = 'wheat',
    quality = 'A',
    quality_score = 83,
    weight_g = 2500,
    freshness = 100,
    harvested_ts = 2000,
})
assert(type(auto_id) == 'string', 'auto batch_id must be a string')
assert(
    auto_id:match('^sf%-%x%x%x%x%x%x%x%x$') ~= nil,
    ('auto batch_id must match sf-XXXXXXXX, got %s'):format(tostring(auto_id))
)
assert(type(auto_metadata) == 'table', 'auto metadata must be a table')
assert(#auto_metadata.lineage_chain == 0, 'first harvest lineage_chain must be []')
assert(auto_metadata.batch_id == auto_id, 'auto metadata batch_id mismatch')

-- ------------------------------------------------------------
-- Case 2: ValidateMetadata rejects a payload with missing
-- batch_id (the canonical S7 DoD invariant).
-- ------------------------------------------------------------
local missing_id = {
    crop_type = 'wheat',
    weight_g = 2500,
    quality = 'B',
    freshness = 100,
    origin = {
        plot_id = 'mlo_field_extensive_01',
        player_cid = 'citizen-1',
        harvested_ts = 1000,
    },
    lineage_chain = {},
    created_at = 1000,
}
local missing_ok, missing_err = PhysicalItem.ValidateMetadata(missing_id)
assert(missing_ok == false, 'ValidateMetadata must reject missing batch_id')
assert(
    type(missing_err) == 'string' and missing_err:find('batch_id', 1, true),
    ('expected batch_id error, got %s'):format(tostring(missing_err))
)

-- ------------------------------------------------------------
-- Case 3: ValidateMetadata rejects freshness = 150 (must be in
-- the integer range [0, 100]).
-- ------------------------------------------------------------
local over_fresh = {
    batch_id = 'sf-deadbeef',
    crop_type = 'wheat',
    weight_g = 2500,
    quality = 'B',
    freshness = 150,
    origin = {
        plot_id = 'mlo_field_extensive_01',
        player_cid = 'citizen-1',
        harvested_ts = 1000,
    },
    lineage_chain = {},
    created_at = 1000,
}
local fresh_ok, fresh_err = PhysicalItem.ValidateMetadata(over_fresh)
assert(fresh_ok == false, 'ValidateMetadata must reject freshness = 150')
assert(
    type(fresh_err) == 'string' and fresh_err:find('freshness', 1, true),
    ('expected freshness error, got %s'):format(tostring(fresh_err))
)

-- ------------------------------------------------------------
-- Case 4: ValidateMetadata rejects an invalid grade ("X").
-- ------------------------------------------------------------
local bad_grade = {
    batch_id = 'sf-cafebabe',
    crop_type = 'wheat',
    weight_g = 2500,
    quality = 'X',
    freshness = 100,
    origin = {
        plot_id = 'mlo_field_extensive_01',
        player_cid = 'citizen-1',
        harvested_ts = 1000,
    },
    lineage_chain = {},
    created_at = 1000,
}
local grade_ok, grade_err = PhysicalItem.ValidateMetadata(bad_grade)
assert(grade_ok == false, "ValidateMetadata must reject grade 'X'")
assert(
    type(grade_err) == 'string' and grade_err:find('quality', 1, true),
    ('expected quality error, got %s'):format(tostring(grade_err))
)

print('physical_item_spec.lua: OK (4 cases)')
