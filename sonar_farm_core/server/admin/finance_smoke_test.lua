-- ============================================================
-- Farm Sonar — Admin command: /sonarfarm:financesmoke
-- ============================================================
--
-- Smoke command for S3 DoD. Tests finance operations:
--   1. Credit operation
--   2. Debit operation
--   3. Idempotency (replay protection)
--   4. Insufficient funds error
--   5. Database record verification
--
-- Usage from server console:
--     sonarfarm:financesmoke <player_source>
--
-- Usage from in-game admin chat (must have ace permission):
--     /sonarfarm:financesmoke [optional source, defaults to caller]
--
-- ACE permission required: `sonar.farm.admin`
-- ============================================================

local function t(key, ...)
    return locale(key, ...)
end


---@param target_src number
local function log_line(target_src, line)
    if target_src == 0 then
        print(line)
    else
        TriggerClientEvent('chat:addMessage', target_src, {
            color = Config.Farm.Chat.BrandColor,
            args  = { t('ui.brand_name'), line },
        })
    end
end

---@param caller_src number
---@param player_src number
local function run_finance_smoke(caller_src, player_src)
    -- Unique suffix per run so idempotency keys never collide across smoke invocations.
    local run_id = tostring(os.time())

    log_line(caller_src, t('finance.smoke.header'))
    log_line(caller_src, t('finance.smoke.run_id', run_id))
    log_line(caller_src, t('finance.smoke.target_source', tostring(player_src)))
    
    local player = Sonar.Farm.Bridge.GetPlayer(player_src)
    if not player then
        log_line(caller_src, t('finance.smoke.no_player'))
        log_line(caller_src, t('finance.smoke.footer'))
        return
    end
    
    log_line(caller_src, t('finance.smoke.player', player.name, player.citizen_id))
    log_line(caller_src, t('finance.smoke.initial_cash', tostring(player.cash)))
    log_line(caller_src, t('finance.smoke.initial_bank', tostring(player.bank)))
    log_line(caller_src, '---')
    
    -- Record balance before mutations so we can verify deltas.
    local balance_before_cash = Sonar.Farm.Bridge.GetMoney(player_src, 'cash')

    -- Test 1: Credit operation
    log_line(caller_src, t('finance.smoke.test_credit'))
    local credit_ok, credit_result = Sonar.Farm.Finance.Credit(
        player_src,
        'cash',
        1000,
        'S3 smoke test credit',
        'smoke_credit_cash_' .. run_id,
        { test = 'S3_smoke' }
    )

    if credit_ok and not credit_result.replay then
        log_line(caller_src, t('finance.smoke.pass_credit_fresh', credit_result.movement_id or 'unknown'))
    elseif credit_ok and credit_result.replay then
        log_line(caller_src, t('finance.smoke.warn_credit_replay_fresh'))
    else
        log_line(caller_src, t('finance.smoke.fail_credit', credit_result.error_code or 'unknown'))
    end
    
    -- Test 2: Idempotency (replay same operation — same run_id key, same inputs)
    log_line(caller_src, t('finance.smoke.test_replay'))
    local replay_ok, replay_result = Sonar.Farm.Finance.Credit(
        player_src,
        'cash',
        1000,
        'S3 smoke test credit',
        'smoke_credit_cash_' .. run_id,
        { test = 'S3_smoke' }
    )

    if replay_ok and replay_result.replay then
        log_line(caller_src, t('finance.smoke.pass_replay'))
    elseif replay_ok and not replay_result.replay then
        log_line(caller_src, t('finance.smoke.fail_replay_false'))
    else
        log_line(caller_src, t('finance.smoke.fail_replay', replay_result.error_code or 'unknown'))
    end
    
    -- Test 3: Verify balance delta after credit (must be +1000 vs pre-credit snapshot)
    log_line(caller_src, t('finance.smoke.test_credit_delta'))
    local balance_after_credit, balance_err = Sonar.Farm.Finance.GetBalance(player_src, 'cash')
    if balance_after_credit then
        local delta = balance_after_credit - balance_before_cash
        if delta == 1000 then
            log_line(caller_src, t('finance.smoke.pass_cash_delta', tostring(delta), tostring(balance_after_credit)))
        else
            log_line(caller_src, t('finance.smoke.fail_cash_delta', tostring(delta), tostring(balance_after_credit)))
        end
    else
        log_line(caller_src, t('finance.smoke.fail_get_balance', balance_err or 'unknown'))
    end
    
    -- Test 4: Debit operation
    log_line(caller_src, t('finance.smoke.test_debit'))
    local balance_before_debit = Sonar.Farm.Bridge.GetMoney(player_src, 'cash')
    local debit_ok, debit_result = Sonar.Farm.Finance.Debit(
        player_src,
        'cash',
        500,
        'S3 smoke test debit',
        'smoke_debit_cash_' .. run_id,
        { test = 'S3_smoke' }
    )

    if debit_ok then
        local balance_after_debit = Sonar.Farm.Bridge.GetMoney(player_src, 'cash')
        local debit_delta = balance_after_debit - balance_before_debit
        if debit_delta == -500 then
            log_line(caller_src, t('finance.smoke.pass_debit', tostring(debit_delta), debit_result.movement_id or 'unknown'))
        else
            log_line(caller_src, t('finance.smoke.fail_debit_delta', tostring(debit_delta)))
        end
    else
        log_line(caller_src, t('finance.smoke.fail_debit', debit_result.error_code or 'unknown'))
    end
    
    -- Test 5: Insufficient funds error
    log_line(caller_src, t('finance.smoke.test_overdraw'))
    local overdraw_ok, overdraw_result = Sonar.Farm.Finance.Debit(
        player_src,
        'cash',
        999999,
        'S3 smoke test overdraw',
        'smoke_overdraw_cash_' .. run_id,
        { test = 'S3_smoke' }
    )
    
    if not overdraw_ok then
        local err_code = overdraw_result and overdraw_result.error_code
        if err_code == 'INSUFFICIENT_FUNDS' then
            log_line(caller_src, t('finance.smoke.pass_overdraw'))
        else
            log_line(caller_src, t('finance.smoke.fail_wrong_error', err_code or 'unknown'))
        end
    else
        log_line(caller_src, t('finance.smoke.fail_overdraw_succeeded'))
    end
    
    -- Test 6: Bank operations
    log_line(caller_src, t('finance.smoke.test_bank_credit'))
    local balance_before_bank = Sonar.Farm.Bridge.GetMoney(player_src, 'bank')
    local bank_credit_ok, bank_credit_result = Sonar.Farm.Finance.Credit(
        player_src,
        'bank',
        2000,
        'S3 smoke test bank credit',
        'smoke_credit_bank_' .. run_id,
        { test = 'S3_smoke' }
    )

    if bank_credit_ok then
        local balance_after_bank = Sonar.Farm.Bridge.GetMoney(player_src, 'bank')
        local bank_delta = balance_after_bank - balance_before_bank
        if bank_delta == 2000 then
            log_line(caller_src, t('finance.smoke.pass_bank_credit', tostring(bank_delta)))
        else
            log_line(caller_src, t('finance.smoke.fail_bank_credit_delta', tostring(bank_delta)))
        end
    else
        log_line(caller_src, t('finance.smoke.fail_bank_credit', bank_credit_result.error_code or 'unknown'))
    end
    
    -- Test 7: CanAfford check
    log_line(caller_src, t('finance.smoke.test_can_afford'))
    local can_afford, afford_err = Sonar.Farm.Finance.CanAfford(player_src, 'cash', 1000)
    if can_afford then
        log_line(caller_src, t('finance.smoke.pass_can_afford'))
    else
        log_line(caller_src, t('finance.smoke.info_can_afford_false', afford_err or 'unknown'))
    end
    
    -- Test 8: Get active adapter
    log_line(caller_src, t('finance.smoke.test_adapter'))
    local adapter_info = Sonar.Farm.Finance.GetActiveAdapter()
    if adapter_info then
        log_line(caller_src, t('finance.smoke.pass_adapter', adapter_info.adapter_name, adapter_info.mode))
    else
        log_line(caller_src, t('finance.smoke.fail_adapter'))
    end
    
    log_line(caller_src, '---')
    log_line(caller_src, t('finance.smoke.final_balances'))
    local final_cash, cash_err = Sonar.Farm.Finance.GetBalance(player_src, 'cash')
    local final_bank, bank_err = Sonar.Farm.Finance.GetBalance(player_src, 'bank')
    log_line(caller_src, t('finance.smoke.balance_cash', tostring(final_cash or cash_err or 'error')))
    log_line(caller_src, t('finance.smoke.balance_bank', tostring(final_bank or bank_err or 'error')))
    log_line(caller_src, t('finance.smoke.footer'))
end

RegisterCommand('sonarfarm:financesmoke', function(source, args)
    local caller_src = tonumber(source) or 0
    
    if caller_src > 0 and not IsPlayerAceAllowed(caller_src, 'sonar.farm.admin') then
        log_line(caller_src, t('finance.smoke.ace_required'))
        return
    end
    
    local target_src
    if args[1] then
        target_src = tonumber(args[1])
    elseif caller_src > 0 then
        target_src = caller_src
    end
    
    if not target_src or target_src <= 0 then
        log_line(caller_src, t('finance.smoke.usage'))
        return
    end
    
    run_finance_smoke(caller_src, target_src)
end, false)
