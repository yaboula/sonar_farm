-- ============================================================
-- Farm Sonar — Admin command: /sonarfarm:bridgetest
-- ============================================================
--
-- Smoke command for S1 DoD. Outputs to the caller's console:
--   1. Active framework (qbox | qbcore | unsupported).
--   2. The full Sonar.Farm.Bridge.Player POJO of the target.
--
-- Usage from server console:
--     sonarfarm:bridgetest <player_source>
--
-- Usage from in-game admin chat (must have ace permission):
--     /sonarfarm:bridgetest [optional source, defaults to caller]
--
-- ACE permission required: `sonar.farm.admin`
--   Add to server.cfg:
--     add_ace group.admin sonar.farm.admin allow
-- ============================================================

local function t(key, ...)
    if _G.locale then
        return locale(key, ...)
    end
    -- Fallback for very early-boot calls before ox_lib is ready.
    if select('#', ...) > 0 then
        return ('%s [%s]'):format(key, table.concat({ ... }, ', '))
    end
    return key
end

---@param target_src number     who to log to (0 = server console).
---@param line       string
local function log_line(target_src, line)
    if target_src == 0 then
        print(line)
    else
        TriggerClientEvent('chat:addMessage', target_src, {
            color = { 200, 255, 0 },
            args  = { 'Farm Sonar', line },
        })
    end
end

---@param caller_src number
---@param player_src number
local function dump_player(caller_src, player_src)
    log_line(caller_src, t('bridge.test.header'))
    log_line(caller_src, t('bridge.test.framework', Sonar.Farm.Bridge.framework or 'unknown'))

    local player = Sonar.Farm.Bridge.GetPlayer(player_src)
    if not player then
        log_line(caller_src, t('bridge.test.no_player', tostring(player_src)))
        log_line(caller_src, t('bridge.test.footer'))
        return
    end

    -- Stable iteration order for human readability.
    local fields = {
        'src', 'citizen_id', 'name',
        'job_name', 'job_grade',
        'cash', 'bank',
        'framework',
    }

    for _, field in ipairs(fields) do
        log_line(caller_src, t('bridge.test.player_line', field, tostring(player[field])))
    end

    log_line(caller_src, t('bridge.test.footer'))
end

RegisterCommand('sonarfarm:bridgetest', function(source, args)
    local caller_src = tonumber(source) or 0

    -- ACE check (skip for console which is always implicitly allowed).
    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, '[Farm Sonar] ACE permission required: sonar.farm.admin')
        return
    end

    -- Target resolution: explicit arg, or self.
    local target_src
    if args[1] then
        target_src = tonumber(args[1])
    elseif caller_src > 0 then
        target_src = caller_src
    end

    if not target_src or target_src <= 0 then
        log_line(caller_src, '[Farm Sonar] usage: sonarfarm:bridgetest <player_source>')
        return
    end

    dump_player(caller_src, target_src)
end, false) -- restricted=false; ACE check is done inside the handler
