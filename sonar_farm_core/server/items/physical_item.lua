Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local PhysicalItem = {}
local VALID_GRADES = { S = true, A = true, B = true, C = true, D = true }

local function is_string_non_empty(value)
    return type(value) == 'string' and value ~= ''
end

local function is_integer_in_range(value, min_value, max_value)
    return type(value) == 'number' and value == math.floor(value) and value >= min_value and value <= max_value
end

local function get_db()
    return Sonar and Sonar.Farm and Sonar.Farm.DB or nil
end

local function safe_trigger(event_name, payload)
    if type(TriggerEvent) == 'function' then
        TriggerEvent(event_name, payload)
    end
end

local function escape_json_string(value)
    local replacements = {
        ['\\'] = '\\\\',
        ['"'] = '\\"',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t',
    }

    return value:gsub('[\\"\b\f\n\r\t]', replacements)
end

local function encode_json_array(values)
    local parts = {}
    for index = 1, #values do
        parts[#parts + 1] = '"' .. escape_json_string(tostring(values[index])) .. '"'
    end
    return '[' .. table.concat(parts, ',') .. ']'
end

local function generate_batch_id()
    return ('sf-%08x'):format(math.random(0, 0xFFFFFFFF))
end

local function build_metadata(params, batch_id, harvested_ts)
    return {
        batch_id = batch_id,
        crop_type = params.crop_type,
        weight_g = params.weight_g,
        quality = params.quality,
        quality_score = params.quality_score,
        freshness = params.freshness,
        origin = {
            plot_id = params.plot_id,
            player_cid = params.player_cid,
            harvested_ts = harvested_ts,
        },
        lineage_chain = params.lineage_chain or {},
        created_at = params.created_at or harvested_ts,
    }
end

local function build_created_payload(params, batch_id, harvested_ts)
    return {
        batch_id = batch_id,
        plot_id = params.plot_id,
        crop_type = params.crop_type,
        player_cid = params.player_cid,
        quality = params.quality,
        quality_score = params.quality_score,
        weight_g = params.weight_g,
        freshness = params.freshness,
        harvested_ts = harvested_ts,
    }
end

local function validate_params(params)
    if type(params) ~= 'table' then
        return false, 'params must be a table'
    end

    if not is_string_non_empty(params.plot_id) then
        return false, 'params.plot_id must be a non-empty string'
    end

    if type(params.crop_id) ~= 'number' or params.crop_id <= 0 or params.crop_id ~= math.floor(params.crop_id) then
        return false, 'params.crop_id must be a positive integer'
    end

    if not is_string_non_empty(params.player_cid) then
        return false, 'params.player_cid must be a non-empty string'
    end

    if not is_string_non_empty(params.crop_type) then
        return false, 'params.crop_type must be a non-empty string'
    end

    if not VALID_GRADES[params.quality] then
        return false, 'params.quality must be S, A, B, C, or D'
    end

    if not is_integer_in_range(params.quality_score, 0, 100) then
        return false, 'params.quality_score must be an integer in [0, 100]'
    end

    if type(params.weight_g) ~= 'number' or params.weight_g <= 0 or params.weight_g ~= math.floor(params.weight_g) then
        return false, 'params.weight_g must be a positive integer'
    end

    if not is_integer_in_range(params.freshness or 100, 0, 100) then
        return false, 'params.freshness must be an integer in [0, 100]'
    end

    if params.lineage_chain ~= nil and type(params.lineage_chain) ~= 'table' then
        return false, 'params.lineage_chain must be a table when provided'
    end

    return true
end

local function batch_id_exists(batch_id)
    local db = get_db()
    if not db or type(db.scalar) ~= 'function' then
        return false
    end

    local found = db.scalar('SELECT `batch_id` FROM `sonar_farm_batches` WHERE `batch_id` = ? LIMIT 1', { batch_id })
    return found ~= nil
end

local function allocate_batch_id(params)
    if params.batch_id then
        return params.batch_id
    end

    for _ = 1, 10 do
        local batch_id = generate_batch_id()
        if not batch_id_exists(batch_id) then
            return batch_id
        end
    end

    return nil
end

local function build_batch_insert_query(params, batch_id, harvested_ts)
    return {
        query = [[
        INSERT INTO `sonar_farm_batches` (
            `batch_id`,
            `plot_id`,
            `crop_id`,
            `player_cid`,
            `crop_type`,
            `quality`,
            `quality_score`,
            `weight_g`,
            `freshness`,
            `lineage_chain`,
            `harvested_ts`,
            `sold_ts`
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
        ]],
        values = {
            batch_id,
            params.plot_id,
            params.crop_id,
            params.player_cid,
            params.crop_type,
            params.quality,
            params.quality_score,
            params.weight_g,
            params.freshness,
            encode_json_array(params.lineage_chain or {}),
            harvested_ts,
        },
    }
end

local function persist_batch(params, batch_id, harvested_ts)
    local db = get_db()
    if not db then
        return false, 'Sonar.Farm.DB is unavailable'
    end

    local query = build_batch_insert_query(params, batch_id, harvested_ts)
    db.execute(query.query, query.values)

    return true
end

local function add_inventory_item(params, metadata)
    local inventory_id = params.inventory_id or params.source or params.src or params.player_src
    if inventory_id == nil then
        return true
    end

    if type(exports) ~= 'table' or not exports.ox_inventory then
        return false, 'ox_inventory export is unavailable'
    end

    local item_name = params.item_name or ('sonar_batch_' .. params.crop_type)
    local ok, result = pcall(function()
        return exports.ox_inventory:AddItem(inventory_id, item_name, 1, metadata)
    end)

    if not ok or result == false then
        return false, tostring(result)
    end

    return true
end

function PhysicalItem.ValidateMetadata(meta)
    if type(meta) ~= 'table' then
        return false, 'metadata must be a table'
    end

    if not is_string_non_empty(meta.batch_id) or not meta.batch_id:match('^sf%-%x%x%x%x%x%x%x%x$') then
        return false, 'metadata.batch_id is invalid'
    end

    if not is_string_non_empty(meta.crop_type) then
        return false, 'metadata.crop_type must be a non-empty string'
    end

    if type(meta.weight_g) ~= 'number' or meta.weight_g <= 0 then
        return false, 'metadata.weight_g must be positive'
    end

    if not VALID_GRADES[meta.quality] then
        return false, 'metadata.quality must be S, A, B, C, or D'
    end

    if not is_integer_in_range(meta.freshness, 0, 100) then
        return false, 'metadata.freshness must be an integer in [0, 100]'
    end

    if type(meta.origin) ~= 'table' then
        return false, 'metadata.origin must be a table'
    end

    if not is_string_non_empty(meta.origin.plot_id) then
        return false, 'metadata.origin.plot_id must be a non-empty string'
    end

    if not is_string_non_empty(meta.origin.player_cid) then
        return false, 'metadata.origin.player_cid must be a non-empty string'
    end

    if type(meta.origin.harvested_ts) ~= 'number' or meta.origin.harvested_ts < 0 then
        return false, 'metadata.origin.harvested_ts must be a non-negative number'
    end

    if type(meta.lineage_chain) ~= 'table' then
        return false, 'metadata.lineage_chain must be a table'
    end

    if type(meta.created_at) ~= 'number' or meta.created_at < 0 then
        return false, 'metadata.created_at must be a non-negative number'
    end

    return true
end

function PhysicalItem.BuildBatchInsertQuery(params, batch_id, harvested_ts)
    return build_batch_insert_query(params, batch_id, harvested_ts)
end

function PhysicalItem.EmitCreated(params, batch_id, harvested_ts)
    local payload = build_created_payload(params, batch_id, harvested_ts)
    safe_trigger('sonar:farm:batch:created', payload)
    safe_trigger('sonar:farm:item:created', payload)
end

function PhysicalItem.CreateBatch(params)
    local ok, err = validate_params(params)
    if not ok then
        return nil, err
    end

    params.freshness = params.freshness or 100

    local batch_id = allocate_batch_id(params)
    if not batch_id then
        return nil, 'could not allocate a unique batch_id'
    end

    local harvested_ts = params.harvested_ts or os.time()
    local metadata = build_metadata(params, batch_id, harvested_ts)
    ok, err = PhysicalItem.ValidateMetadata(metadata)
    if not ok then
        return nil, err
    end

    if params.persist ~= false then
        ok, err = persist_batch(params, batch_id, harvested_ts)
        if not ok then
            return nil, err
        end
    end

    ok, err = add_inventory_item(params, metadata)
    if not ok then
        return nil, err
    end

    if params.emit_events ~= false then
        PhysicalItem.EmitCreated(params, batch_id, harvested_ts)
    end

    return batch_id, metadata
end

Sonar.Farm.PhysicalItem = PhysicalItem
