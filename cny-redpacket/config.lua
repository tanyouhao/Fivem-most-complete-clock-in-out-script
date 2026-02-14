Config = {}

-- ============================================================
-- GENERAL SETTINGS
-- ============================================================

-- Language for notifications ('en' = English, 'zh' = Chinese)
Config.Locale = 'en'

-- Remove the red packet item from inventory after opening
Config.RemoveOnOpen = true

-- Cooldown in seconds between opening packets (prevents spam)
Config.OpenCooldown = 5

-- ============================================================
-- RED PACKET ITEMS
-- You can define multiple types of red packets
-- Each entry = one registered usable item in your database
-- ============================================================

Config.RedPackets = {
    -- --------------------------------------------------------
    -- NORMAL RED PACKET
    -- --------------------------------------------------------
    {
        itemName    = 'cny_redpacket',          -- Must match your items table
        label       = 'Red Packet',
        minMoney    = 1000,                     -- Minimum cash reward
        maxMoney    = 8888,                     -- Maximum cash reward
        moneyType   = 'cash',                   -- 'cash' or 'bank'
        luckyNumber = 8888,                     -- Jackpot amount (exact hit)
        luckyChance = 5,                        -- % chance to hit jackpot
        bonusItems  = {                         -- Additional item rewards (optional)
            { name = 'bread', count = 2, chance = 30 },  -- 30% chance
            { name = 'water', count = 2, chance = 30 },  -- 30% chance
        },
        animation   = 'normal',                 -- Animation type: 'normal' or 'gold'
        notification = 'You opened a ~r~Red Packet~s~ and received ~g~$%s~s~!',
    },

    -- --------------------------------------------------------
    -- GOLDEN RED PACKET (rarer, higher reward)
    -- --------------------------------------------------------
    {
        itemName    = 'cny_redpacket_gold',
        label       = 'Golden Red Packet',
        minMoney    = 5000,
        maxMoney    = 28888,
        moneyType   = 'cash',
        luckyNumber = 88888,
        luckyChance = 3,
        bonusItems  = {
            { name = 'bread', count = 5, chance = 50 },
            { name = 'water', count = 5, chance = 50 },
        },
        animation   = 'gold',
        notification = 'You opened a ~y~Golden Red Packet~s~ and received ~g~$%s~s~!',
    },
}

-- ============================================================
-- ADMIN SETTINGS
-- ============================================================

-- Command to give red packets to all online players
Config.AdminCommand       = 'giveredpackets'
Config.AdminCommandGold   = 'givegoldpackets'

-- Who can use the admin commands
-- 'admin', 'superadmin', or use ace permissions
Config.AdminGroups = { 'admin', 'superadmin' }

-- Amount to give per player when using the admin command
Config.AdminGiveCount = 1

-- ============================================================
-- NUI SETTINGS
-- ============================================================

-- How long the red packet animation plays (ms)
Config.AnimationDuration = 3000

-- Sound volume (0.0 - 1.0)
Config.SoundVolume = 0.5

-- ============================================================
-- MESSAGES (Bilingual support)
-- ============================================================

Config.Messages = {
    en = {
        opened_packet     = 'You opened a Red Packet and received $%s!',
        opened_gold       = 'You opened a Golden Red Packet and received $%s!',
        bonus_item        = 'Bonus: You also received %sx %s!',
        jackpot           = 'JACKPOT! You hit the lucky number and received $%s!',
        cooldown          = 'Please wait before opening another packet!',
        no_item           = 'You do not have this item!',
        admin_gave        = 'Admin gave everyone %s red packet(s)!',
        admin_no_perm     = 'You do not have permission to use this command.',
        inventory_full    = 'Your inventory is full!',
    },
    zh = {
        opened_packet     = '你打开了一个红包，获得了 $%s！',
        opened_gold       = '你打开了一个金色红包，获得了 $%s！',
        bonus_item        = '额外奖励：你还获得了 %sx %s！',
        jackpot           = '大吉大利！你中了幸运数字，获得了 $%s！',
        cooldown          = '请稍等再打开下一个红包！',
        no_item           = '你没有这个物品！',
        admin_gave        = '管理员给每人发放了 %s 个红包！',
        admin_no_perm     = '你没有权限使用此命令。',
        inventory_full    = '你的背包已满！',
    },
}

-- Helper to get message
function GetMessage(key, ...)
    local lang = Config.Messages[Config.Locale] or Config.Messages['en']
    local msg = lang[key] or key
    if ... then
        return string.format(msg, ...)
    end
    return msg
end
