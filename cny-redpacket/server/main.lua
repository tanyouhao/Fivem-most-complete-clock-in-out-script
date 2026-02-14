ESX = exports['es_extended']:getSharedObject()

-- Track cooldowns per player
local PlayerCooldowns = {}

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

        -- Give money reward
        if packet.moneyType == 'bank' then
            xPlayer.addAccountMoney('bank', reward, 'CNY Red Packet reward')
        else
            xPlayer.addMoney(reward, 'CNY Red Packet reward')
        end

        -- Check for bonus items
        local bonusReceived = {}
        if packet.bonusItems then
            for _, bonusItem in ipairs(packet.bonusItems) do
                local roll = math.random(1, 100)
                if roll <= bonusItem.chance then
                    -- Check if player can carry the item
                    if xPlayer.canCarryItem(bonusItem.name, bonusItem.count) then
                        xPlayer.addInventoryItem(bonusItem.name, bonusItem.count)
                        table.insert(bonusReceived, {
                            name  = bonusItem.name,
                            count = bonusItem.count,
                        })
                    end
                end
            end
        end

        -- Tell client to play the opening animation
        TriggerClientEvent('cny-redpacket:client:openPacket', playerId, {
            reward       = reward,
            isJackpot    = isJackpot,
            bonusItems   = bonusReceived,
            animation    = packet.animation,
            notification = string.format(packet.notification, tostring(reward)),
        })

        -- Send bonus item notifications
        for _, bonus in ipairs(bonusReceived) do
            xPlayer.showNotification(GetMessage('bonus_item', tostring(bonus.count), bonus.name))
        end

        -- Jackpot announcement
        if isJackpot then
            xPlayer.showNotification(GetMessage('jackpot', tostring(reward)))
            -- Optional: announce jackpot to all players
            TriggerClientEvent('esx:showNotification', -1,
                '~y~[CNY] ~s~' .. xPlayer.getName() .. ' hit the ~r~JACKPOT~s~ and won ~g~$' .. tostring(reward) .. '~s~!'
            )
        end

        print(('[cny-redpacket] %s (ID: %s) opened %s -> $%s%s'):format(
            xPlayer.getName(), playerId, packet.itemName, reward, isJackpot and ' (JACKPOT!)' or ''
        ))
    end)
end

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
end)
