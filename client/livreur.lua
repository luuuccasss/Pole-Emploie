local deliveryPoints = {
    {x = -42.25, y = -1749.45, z = 29.42},  -- Davis
    {x = 345.87, y = -2047.42, z = 21.50},  -- La Puerta
    {x = 1145.67, y = -980.14, z = 46.42},  -- Strawberry
    {x = -709.41, y = -905.65, z = 19.22},  -- Little Seoul
    {x = 1212.12, y = -1389.48, z = 35.37}, -- El Burro Heights
    {x = 2566.33, y = 377.98, z = 108.62},  -- Tataviam Mountains
    {x = -255.55, y = -344.22, z = 29.41},  -- Alta
    {x = 1143.56, y = -1510.23, z = 34.69}, -- La Mesa
    {x = 1693.56, y = 3756.98, z = 34.70},  -- Sandy Shores
    {x = -47.87, y = -1758.23, z = 29.42},  -- Davis (Supermarket)
    {x = 818.23, y = -2160.78, z = 29.62},  -- Rancho
    {x = 2569.45, y = 302.77, z = 108.46},  -- Tataviam Mountains (another point)
    {x = -705.12, y = -913.45, z = 19.21},  -- Little Seoul (another point)
    {x = 185.68, y = -1562.47, z = 28.80},  -- Chamberlain Hills
    {x = 241.78, y = -1004.65, z = 29.27}   -- Legion Square
}

local isOnDelivery = false
local currentDeliveryPoint = nil
local deliveryNPC = nil
local deliveryBlip = nil

function ShowHelpNotification(msg)
    SetTextComponentFormat("STRING")
    AddTextComponentString(msg)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function GetGroundZ(x, y, z)
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    while not foundGround do
        Wait(0)
        foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    end
    return groundZ
end

function SpawnDeliveryNPC(x, y, z)
    local modelHash = GetHashKey("a_m_m_farmer_01")
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end

    local groundZ = GetGroundZ(x, y, z)

    local npc = CreatePed(4, modelHash, x, y, groundZ, 0.0, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedCanBeTargetted(npc, false)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CHEERING", 0, true)

    return npc
end

function DeleteDeliveryNPC(npc)
    if DoesEntityExist(npc) then
        DeleteEntity(npc)
    end
end

-- Fonction pour créer un blip temporaire
function CreateDeliveryBlip(x, y, z)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, 1) -- Icône du blip, peut être changé
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5) -- Couleur du blip, peut être changé
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Livreur | Point de livraison")
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Fonction pour supprimer le blip temporaire
function DeleteDeliveryBlip(blip)
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

function StartDeliveryService()
    local playerData = ESX.GetPlayerData()
    
    if playerData.job and playerData.job.name == 'livreur' then
        isOnDelivery = true
        currentDeliveryPoint = deliveryPoints[math.random(#deliveryPoints)]
        SetNewWaypoint(currentDeliveryPoint.x, currentDeliveryPoint.y)
        deliveryNPC = SpawnDeliveryNPC(currentDeliveryPoint.x, currentDeliveryPoint.y, currentDeliveryPoint.z)
        deliveryBlip = CreateDeliveryBlip(currentDeliveryPoint.x, currentDeliveryPoint.y, currentDeliveryPoint.z)
        ESX.ShowNotification("Livraison commencée ! Rendez-vous au point de livraison.")

        Citizen.CreateThread(function()
            while isOnDelivery do
                Citizen.Wait(0)
                local playerCoords = GetEntityCoords(PlayerPedId())

                if currentDeliveryPoint and GetDistanceBetweenCoords(playerCoords, currentDeliveryPoint.x, currentDeliveryPoint.y, currentDeliveryPoint.z, true) < 2.0 then
                    ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour livrer le colis")

                    if IsControlJustReleased(0, 38) then
                        ESX.TriggerServerCallback('delivery:reward', function(success)
                            if success then
                                ESX.ShowNotification("Colis livré !")
                                DeleteDeliveryNPC(deliveryNPC)
                                DeleteDeliveryBlip(deliveryBlip)
                                isOnDelivery = false
                                currentDeliveryPoint = nil
                                deliveryNPC = nil
                                deliveryBlip = nil
                            else
                                ESX.ShowNotification("Erreur lors de la livraison. Réessayez.")
                            end
                        end)
                    end
                end

                if currentDeliveryPoint then
                    DrawMarker(21, currentDeliveryPoint.x, currentDeliveryPoint.y, currentDeliveryPoint.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 255, false, false, 2, nil, nil, false)
                end
            end

            -- Attendre que le joueur appuie sur "E" pour démarrer une nouvelle livraison
            while not isOnDelivery do
                Citizen.Wait(0)
                ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour commencer une nouvelle livraison")

                if IsControlJustReleased(0, 38) then
                    StartDeliveryService()
                end
            end
        end)
    else
        ESX.ShowNotification("Vous devez être livreur pour commencer une livraison.")
    end
end

-- Ajouter une récompense pour chaque livraison
RegisterNetEvent('delivery:reward')
AddEventHandler('delivery:reward', function()
    local xPlayer = ESX.GetPlayerData()
    TriggerServerEvent('esx:addMoney', 500)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local vehicleModel = GetEntityModel(vehicle)

            if vehicleModel == GetHashKey("boxville2") and not isOnDelivery then
                StartDeliveryService()
            end
        end
    end
end)
