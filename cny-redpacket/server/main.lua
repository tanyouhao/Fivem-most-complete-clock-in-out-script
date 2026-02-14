ESX = exports['es_extended']:getSharedObject()

-- Track cooldowns per player
local PlayerCooldowns = {}

-- Track pending rewards (given after animation finishes)
local PendingRewards = {}

-- ============================================================
-- REGISTER ALL RED PACKET USABLE ITEMS
-- ============================================================

for _, packet in ipairs(Config.RedPackets) do
    ESX.RegisterUsableItem(packet.itemName, function(playerId)
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if not xPlayer then return end

        -- Check cooldown
        local currentTime = os.time()
        if PlayerCooldowns[playerId] and (currentTime - PlayerCooldowns[playerId]) < Config.OpenCooldown then
            xPlayer.showNotification(GetMessage('cooldown'))
            return
        end

        -- Verify the player actually has the item (server-side check)
        local item = xPlayer.getInventoryItem(packet.itemName)
        if not item or item.count < 1 then
            xPlayer.showNotification(GetMessage('no_item'))
            return
        end

        -- Remove item FIRST to prevent duplication exploits
        if Config.RemoveOnOpen then
            xPlayer.removeInventoryItem(packet.itemName, 1)
        end

        -- Set cooldown
        PlayerCooldowns[playerId] = currentTime

        -- Calculate reward
        local reward = 0
        local isJackpot = false

        -- Check for jackpot
        local jackpotRoll = math.random(1, 100)
        if jackpotRoll <= packet.luckyChance then
            reward = packet.luckyNumber
            isJackpot = true
        else
            reward = math.random(packet.minMoney, packet.maxMoney)
        end

        -- Pre-roll bonus items (server-side) but don't give yet
        local bonusToGive = {}
        if packet.bonusItems then
            for _, bonusItem in ipairs(packet.bonusItems) do
                local roll = math.random(1, 100)
                if roll <= bonusItem.chance then
                    if xPlayer.canCarryItem(bonusItem.name, bonusItem.count) then
                        table.insert(bonusToGive, {
                            name  = bonusItem.name,
                            count = bonusItem.count,
                        })
                    end
                end
            end
        end

        -- Store pending reward — money is given AFTER animation finishes
        PendingRewards[playerId] = {
            reward      = reward,
            isJackpot   = isJackpot,
            moneyType   = packet.moneyType,
            bonusItems  = bonusToGive,
            notification = string.format(packet.notification, tostring(reward)),
            itemName    = packet.itemName,
        }

        -- Tell client to play the opening animation FIRST (no money given yet)
        TriggerClientEvent('cny-redpacket:client:openPacket', playerId, {
            reward       = reward,
            isJackpot    = isJackpot,
            bonusItems   = bonusToGive,
            animation    = packet.animation,
            notification = string.format(packet.notification, tostring(reward)),
        })

        print(('[cny-redpacket] %s (ID: %s) opened %s -> $%s%s (pending claim)'):format(
            xPlayer.getName(), playerId, packet.itemName, reward, isJackpot and ' (JACKPOT!)' or ''
        ))
    end)
end

-- ============================================================
-- CLAIM REWARD AFTER ANIMATION (triggered by client)
-- ============================================================

RegisterNetEvent('cny-redpacket:server:claimReward')
AddEventHandler('cny-redpacket:server:claimReward', function()
    local playerId = source
    local pending = PendingRewards[playerId]
    if not pending then return end

    -- Clear pending immediately to prevent double-claim
    PendingRewards[playerId] = nil

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    -- NOW give the money
    if pending.moneyType == 'bank' then
        xPlayer.addAccountMoney('bank', pending.reward, 'CNY Red Packet reward')
    else
        xPlayer.addMoney(pending.reward, 'CNY Red Packet reward')
    end

    -- Give bonus items
    for _, bonus in ipairs(pending.bonusItems) do
        if xPlayer.canCarryItem(bonus.name, bonus.count) then
            xPlayer.addInventoryItem(bonus.name, bonus.count)
        end
    end

    -- Send bonus item notifications
    for _, bonus in ipairs(pending.bonusItems) do
        xPlayer.showNotification(GetMessage('bonus_item', tostring(bonus.count), bonus.name))
    end

    -- Jackpot announcement
    if pending.isJackpot then
        xPlayer.showNotification(GetMessage('jackpot', tostring(pending.reward)))
        TriggerClientEvent('esx:showNotification', -1,
            '~y~[CNY] ~s~' .. xPlayer.getName() .. ' hit the ~r~JACKPOT~s~ and won ~g~$' .. tostring(pending.reward) .. '~s~!'
        )
    end

    print(('[cny-redpacket] %s (ID: %s) claimed reward -> $%s%s'):format(
        xPlayer.getName(), playerId, pending.reward, pending.isJackpot and ' (JACKPOT!)' or ''
    ))
end)

-- ============================================================
-- ADMIN COMMANDS
-- ============================================================

-- Helper: check if player is admin
local function IsAdmin(xPlayer)
    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            return true
        end
    end
    return false
end

-- Give normal red packets to all online players
RegisterCommand(Config.AdminCommand, function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source == 0 or (xPlayer and IsAdmin(xPlayer)) then
        local count = tonumber(args[1]) or Config.AdminGiveCount
        local players = ESX.GetExtendedPlayers()

        local given = 0
        for _, targetPlayer in pairs(players) do
            -- Skip the admin who issued the command
            if targetPlayer.source ~= source then
                if targetPlayer.canCarryItem('cny_redpacket', count) then
                    targetPlayer.addInventoryItem('cny_redpacket', count)
                    targetPlayer.showNotification(GetMessage('admin_gave', tostring(count)))
                    given = given + 1
                else
                    targetPlayer.showNotification(GetMessage('inventory_full'))
                end
            end
        end

        if source ~= 0 then
            xPlayer.showNotification('Gave ' .. count .. ' red packet(s) to ' .. given .. ' player(s).')
        end
        print(('[cny-redpacket] Admin gave %d red packet(s) to %d player(s)'):format(count, given))
    else
        if xPlayer then
            xPlayer.showNotification(GetMessage('admin_no_perm'))
        end
    end
end, false)

-- Give golden red packets to all online players
RegisterCommand(Config.AdminCommandGold, function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source == 0 or (xPlayer and IsAdmin(xPlayer)) then
        local count = tonumber(args[1]) or Config.AdminGiveCount
        local players = ESX.GetExtendedPlayers()

        local given = 0
        for _, targetPlayer in pairs(players) do
            -- Skip the admin who issued the command
            if targetPlayer.source ~= source then
                if targetPlayer.canCarryItem('cny_redpacket_gold', count) then
                    targetPlayer.addInventoryItem('cny_redpacket_gold', count)
                    targetPlayer.showNotification(GetMessage('admin_gave', tostring(count)))
                    given = given + 1
                else
                    targetPlayer.showNotification(GetMessage('inventory_full'))
                end
            end
        end

        if source ~= 0 then
            xPlayer.showNotification('Gave ' .. count .. ' golden red packet(s) to ' .. given .. ' player(s).')
        end
        print(('[cny-redpacket] Admin gave %d golden red packet(s) to %d player(s)'):format(count, given))
    else
        if xPlayer then
            xPlayer.showNotification(GetMessage('admin_no_perm'))
        end
    end
end, false)

-- ============================================================
-- CLEANUP: Remove cooldown when player disconnects
-- ============================================================

AddEventHandler('playerDropped', function()
    local playerId = source
    PlayerCooldowns[playerId] = nil
    PendingRewards[playerId] = nil
end)
