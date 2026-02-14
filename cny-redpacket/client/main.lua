local isOpening = false

-- ============================================================
-- RECEIVE OPEN PACKET EVENT FROM SERVER
-- ============================================================

RegisterNetEvent('cny-redpacket:client:openPacket')
AddEventHandler('cny-redpacket:client:openPacket', function(data)
    if isOpening then return end
    isOpening = true

    local playerPed = PlayerPedId()

    -- Play opening animation (non-blocking, does NOT freeze player)
    PlayOpenAnimation(playerPed)

    -- Show NUI red packet animation
    SendNUIMessage({
        action    = 'openPacket',
        reward    = data.reward,
        isJackpot = data.isJackpot,
        animation = data.animation or 'normal',
        duration  = Config.AnimationDuration,
    })

    -- DO NOT set NUI focus — this is what breaks inventory!
    -- We only send a message to the NUI, no focus needed.

    -- Show notification after a short delay
    Citizen.SetTimeout(Config.AnimationDuration, function()
        -- Show the reward notification
        ESX.ShowNotification(data.notification)

        -- Show bonus items
        if data.bonusItems and #data.bonusItems > 0 then
            for _, bonus in ipairs(data.bonusItems) do
                ESX.ShowNotification(GetMessage('bonus_item', tostring(bonus.count), bonus.name))
            end
        end

        -- Stop animation safely
        StopOpenAnimation(playerPed)

        -- Close NUI
        SendNUIMessage({ action = 'closePacket' })

        isOpening = false
    end)
end)

-- ============================================================
-- ANIMATION FUNCTIONS
-- Safe animations that do NOT block inventory or controls
-- ============================================================

function PlayOpenAnimation(ped)
    -- Use a simple animation that doesn't lock the player
    local animDict = 'anim@heists@ornate_bank@grab_cash_briefcase'
    local animName = 'grab'

    -- Request the animation dictionary
    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    if HasAnimDictLoaded(animDict) then
        -- Upper body only flag (49) — player can still move and open inventory
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, Config.AnimationDuration, 49, 0, false, false, false)
    end
end

function StopOpenAnimation(ped)
    ClearPedTasks(ped)
end

-- ============================================================
-- PARTICLE EFFECTS (optional visual flair)
-- ============================================================

function PlayConfettiEffect(ped)
    local particleDict = 'scr_indep_fireworks'
    local particleName = 'scr_indep_firework_starburst'

    RequestNamedPtfxAsset(particleDict)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(particleDict) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    if HasNamedPtfxAssetLoaded(particleDict) then
        UseParticleFxAsset(particleDict)
        local coords = GetEntityCoords(ped)
        local effect = StartParticleFxLoopedAtCoord(
            particleName,
            coords.x, coords.y, coords.z + 1.5,
            0.0, 0.0, 0.0,
            0.5, false, false, false, false
        )

        -- Stop the effect after a moment
        Citizen.SetTimeout(2000, function()
            StopParticleFxLooped(effect, false)
            RemoveNamedPtfxAsset(particleDict)
        end)
    end
end

-- ============================================================
-- NUI CALLBACKS (safety — ensure NUI is always closeable)
-- ============================================================

RegisterNUICallback('packetClosed', function(data, cb)
    -- NUI reports it finished, make sure everything is clean
    isOpening = false
    cb('ok')
end)
