local ESX = exports['es_extended']:getSharedObject()

local minerPoints = {
    mining = { x = -600.0, y = 2090.0, z = 131.0 },     -- Point de minage
    processing = { x = 1100.0, y = -2000.0, z = 30.0 }, -- Point de traitement
    selling = { x = 254.3665, y = -1799.9642, z = 27.1131 }      -- Point de vente
}

local isMining = false
local isProcessing = false
local isSelling = false
local sellingCooldown = false
local playerJob = nil

local function addMinerBlips()
    -- Blip pour le point de minage
    if minerPoints.mining then
        local miningBlip = AddBlipForCoord(minerPoints.mining.x, minerPoints.mining.y, minerPoints.mining.z)
        SetBlipSprite(miningBlip, 618)
        SetBlipDisplay(miningBlip, 4)
        SetBlipScale(miningBlip, 0.9)
        SetBlipColour(miningBlip, 5)
        SetBlipAsShortRange(miningBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Mine | Minage")
        EndTextCommandSetBlipName(miningBlip)
    end

    -- Blip pour le point de traitement
    if minerPoints.processing then
        local processingBlip = AddBlipForCoord(minerPoints.processing.x, minerPoints.processing.y, minerPoints.processing.z)
        SetBlipSprite(processingBlip, 618)
        SetBlipDisplay(processingBlip, 4)
        SetBlipScale(processingBlip, 0.9)
        SetBlipColour(processingBlip, 5)
        SetBlipAsShortRange(processingBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Mine | Traitement")
        EndTextCommandSetBlipName(processingBlip)
    end

    -- Blip pour le point de vente
    if minerPoints.selling then
        local sellingBlip = AddBlipForCoord(minerPoints.selling.x, minerPoints.selling.y, minerPoints.selling.z)
        SetBlipSprite(sellingBlip, 618)
        SetBlipDisplay(sellingBlip, 4)
        SetBlipScale(sellingBlip, 0.9)
        SetBlipColour(sellingBlip, 5)
        SetBlipAsShortRange(sellingBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Mine | Vente")
        EndTextCommandSetBlipName(sellingBlip)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        playerJob = ESX.GetPlayerData().job
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if playerJob and playerJob.name == 'miner' then
            addMinerBlips()
            break
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if playerJob and playerJob.name == 'miner' then
            local playerCoords = GetEntityCoords(PlayerPedId())

            local miningDistance = minerPoints.mining and GetDistanceBetweenCoords(playerCoords, minerPoints.mining.x, minerPoints.mining.y, minerPoints.mining.z, true)
            local processingDistance = minerPoints.processing and GetDistanceBetweenCoords(playerCoords, minerPoints.processing.x, minerPoints.processing.y, minerPoints.processing.z, true)
            local sellingDistance = minerPoints.selling and GetDistanceBetweenCoords(playerCoords, minerPoints.selling.x, minerPoints.selling.y, minerPoints.selling.z, true)

            if miningDistance and miningDistance < 1.5 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour miner")
                if IsControlJustReleased(0, 38) and not isMining then
                    isMining = true
                    TriggerServerEvent('miner:startMining')
                    ESX.ShowNotification("Vous avez commencé à miner.")
                end
            elseif processingDistance and processingDistance < 1.5 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour traiter")
                if IsControlJustReleased(0, 38) and not isProcessing then
                    isProcessing = true
                    TriggerServerEvent('miner:startProcessing')
                end
            elseif sellingDistance and sellingDistance < 1.5 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre")
                if IsControlJustReleased(0, 38) and not isSelling and not sellingCooldown then
                    isSelling = true
                    sellingCooldown = true
                    TriggerServerEvent('miner:startSelling')
                end
            end
        end
    end
end)

RegisterNetEvent('miner:playMiningAnimation')
AddEventHandler('miner:playMiningAnimation', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("amb@world_human_hammering@male@base")
    while not HasAnimDictLoaded("amb@world_human_hammering@male@base") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "amb@world_human_hammering@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(2000)
    ClearPedTasks(playerPed)
    isMining = false
end)

RegisterNetEvent('miner:playProcessingAnimation')
AddEventHandler('miner:playProcessingAnimation', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(5000)
    ClearPedTasks(playerPed)
    isProcessing = false
end)

RegisterNetEvent('miner:playSellingAnimation')
AddEventHandler('miner:playSellingAnimation', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(2000)
    ClearPedTasks(playerPed)
    isSelling = false
end)

RegisterNetEvent('miner:notify')
AddEventHandler('miner:notify', function(message)
    ESX.ShowNotification(message)
end)

RegisterNetEvent('miner:processingComplete')
AddEventHandler('miner:processingComplete', function()
    isProcessing = false
end)

RegisterNetEvent('miner:sellingComplete')
AddEventHandler('miner:sellingComplete', function()
    Citizen.Wait(1000)
    isSelling = false
    sellingCooldown = false
end)
