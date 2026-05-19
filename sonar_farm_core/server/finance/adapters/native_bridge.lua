Sonar = Sonar or {}
Sonar.Farm = Sonar.Farm or {}
Sonar.Farm.Finance = Sonar.Farm.Finance or {}
Sonar.Farm.Finance.Adapters = Sonar.Farm.Finance.Adapters or {}

local adapter = {}

adapter.name = 'native_bridge'
adapter.mode = 'bridge'

local function get_bridge()
    if not Sonar.Farm.Bridge then
        return nil
    end

    if Sonar.Farm.Bridge.framework == 'unsupported' then
        return nil
    end

    return Sonar.Farm.Bridge
end

function adapter.GetBalance(src, account)
    local bridge = get_bridge()
    if not bridge or type(bridge.GetMoney) ~= 'function' then
        return false, 0, 'ADAPTER_UNAVAILABLE'
    end

    return true, bridge.GetMoney(src, account), nil
end

function adapter.Credit(src, account, amount, reason)
    local bridge = get_bridge()
    if not bridge or type(bridge.AddMoney) ~= 'function' then
        return false, 'ADAPTER_UNAVAILABLE'
    end

    local ok = bridge.AddMoney(src, account, amount, reason)
    if not ok then
        return false, 'MUTATION_FAILED'
    end

    return true, nil
end

function adapter.Debit(src, account, amount, reason)
    local bridge = get_bridge()
    if not bridge or type(bridge.RemoveMoney) ~= 'function' then
        return false, 'ADAPTER_UNAVAILABLE'
    end

    local ok, err = bridge.RemoveMoney(src, account, amount, reason)
    if not ok then
        if err == 'insufficient funds' then
            return false, 'INSUFFICIENT_FUNDS'
        end

        return false, 'MUTATION_FAILED'
    end

    return true, nil
end

Sonar.Farm.Finance.Adapters.native_bridge = adapter
