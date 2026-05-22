Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}

local db = {}

local function mysql()
    local mysql_global = MySQL

    if type(mysql_global) ~= 'table' then
        error('oxmysql global MySQL is unavailable. Ensure @oxmysql/lib/MySQL.lua is loaded before Farm Sonar DB scripts.', 3)
    end

    return mysql_global
end

local function await_operation(operation_name, query, params)
    if type(query) ~= 'string' or query == '' then
        error(('db.%s requires a non-empty SQL query'):format(operation_name), 3)
    end

    local mysql_operation = mysql()[operation_name]
    if type(mysql_operation) ~= 'table' or type(mysql_operation.await) ~= 'function' then
        error(('oxmysql MySQL.%s.await is unavailable'):format(operation_name), 3)
    end

    local ok, result = pcall(function()
        return mysql_operation.await(query, params or {})
    end)

    if not ok then
        error(('DB %s failed: %s'):format(operation_name, tostring(result)), 3)
    end

    return result
end

function db.scalar(query, params)
    return await_operation('scalar', query, params)
end

function db.row(query, params)
    return await_operation('single', query, params)
end

function db.rows(query, params)
    return await_operation('query', query, params)
end

function db.execute(query, params)
    return await_operation('query', query, params)
end

function db.transaction(queries)
    if type(queries) ~= 'table' then
        error('db.transaction requires a table of transaction queries', 2)
    end

    local mysql_transaction = mysql().transaction
    if type(mysql_transaction) ~= 'table' or type(mysql_transaction.await) ~= 'function' then
        error('oxmysql MySQL.transaction.await is unavailable', 2)
    end

    local ok, result = pcall(function()
        return mysql_transaction.await(queries)
    end)

    if not ok then
        error(('DB transaction failed: %s'):format(tostring(result)), 2)
    end

    if result == false or result == nil then
        error('DB transaction failed: oxmysql returned a falsy result', 2)
    end

    return result
end

function db.ping()
    local result = db.scalar('SELECT 1', {})
    return tonumber(result) == 1
end

Sonar.Farm.DB = db
