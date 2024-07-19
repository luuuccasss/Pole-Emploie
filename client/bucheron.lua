ESX = exports['es_extended']:getSharedObject()

local isCutting = false
local hasCutTree = false
local treeCoords = {
    {x = -557.6323, y = 5417.2104, z = 62.9632},
    {x = -585.1368, y = 5446.3745, z = 60.2614},
    {x = -596.8218, y = 5472.1528, z = 56.8069},
    {x = -600.1234, y = 5480.5678, z = 55.7890},
    {x = -610.5678, y = 5490.1234, z = 54.6789},
}
local sellPoint = {x = -468.2799, y = 5357.1880, z = 80.7816, heading = 93.7980}
local treeBlip = nil
local sellNPC
local currentTreeIndex = 1
local woodCount = 0
local isNearSellPoint = false
local playerJob = nil

local function getPlayerJob()
    ESX.TriggerServerCallback('esx:getPlayerData', function(data)
        playerJob = data.job.name
    end)
end

local function getRandomTreeIndex()
    return math.random(1, #treeCoords)
end

local function addTreeBlip(index)
    if treeBlip then
        RemoveBlip(treeBlip)
    end
    local coords = treeCoords[index]
    treeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(treeBlip, 1)
    SetBlipColour(treeBlip, 1)
    SetBlipScale(treeBlip, 0.5)
    SetBlipAsShortRange(treeBlip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Arbre à couper")
    EndTextCommandSetBlipName(treeBlip)
end

local function cutTree()
    isCutting = true
    hasCutTree = false
    TaskStartScenarioInPlace(PlayerPedId(), 'world_human_gardener_plant', 0, true)
    Citizen.Wait(10000)
    ClearPedTasks(PlayerPedId())
    hasCutTree = true
    TriggerEvent('bucheron:giveWood')

    currentTreeIndex = getRandomTreeIndex()
    addTreeBlip(currentTreeIndex)

    isCutting = false
end

local function createSellNPC()
    local model = GetHashKey("s_m_y_ammucity_01")

    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end

    sellNPC = CreatePed(4, model, sellPoint.x, sellPoint.y, sellPoint.z - 1, 0.0, false, true)
    SetEntityHeading(sellNPC, sellPoint.heading)
    FreezeEntityPosition(sellNPC, true)
    SetEntityInvincible(sellNPC, true)
    SetBlockingOfNonTemporaryEvents(sellNPC, true)
end

local function createSellBlip()
    local blip = AddBlipForCoord(sellPoint.x, sellPoint.y, sellPoint.z)
    SetBlipSprite(blip, 431)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Bûcheron | Vente")
    EndTextCommandSetBlipName(blip)
end

local function OpenSellMenu()
    if not RMenu then
        RMenu = {}
    end

    if not RMenu['default'] then
        RMenu['default'] = RageUI.CreateMenu("", "~w~Sélectionnez la quantité à vendre")
    end

    RageUI.Visible(RMenu['default'], true)

    Citizen.CreateThread(function()
        while RageUI.Visible(RMenu['default']) do
            Citizen.Wait(1)
            RageUI.IsVisible(RMenu['default'], function()
                RageUI.Separator("Nombre de bois : " .. tostring(woodCount))

                RageUI.Button("Vendre 1 bois", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('bucheron:sellWood', 1)
                        RageUI.CloseAll()
                    end
                })

                RageUI.Button("Vendre 5 bois", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('bucheron:sellWood', 5)
                        RageUI.CloseAll()
                    end
                })

                RageUI.Button("Vendre 10 bois", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('bucheron:sellWood', 10)
                        RageUI.CloseAll()
                    end
                })

                RageUI.Button("Vendre une quantité spécifique", nil, {}, true, {
                    onSelected = function()
                        local amount = tonumber(KeyboardInput("Combien de bois voulez-vous vendre?", "", "", 10))
                        if amount and amount > 0 and amount == math.floor(amount) then
                            TriggerServerEvent('bucheron:sellWood', amount)
                            RageUI.CloseAll()
                        else
                            ESX.ShowNotification("Quantité invalide")
                        end
                    end
                })

                RageUI.Button("Fermer", nil, {RightLabel = "→"}, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                    end
                })
            end)
        end
    end)
end

function KeyboardInput(textEntry, exampleText, defaultText, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', textEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", defaultText, "", "", "", maxLength)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        return nil
    end
end

Citizen.CreateThread(function()
    while playerJob == nil do
        getPlayerJob()
        Citizen.Wait(1000)
    end

    if playerJob == 'bucheron' then
        currentTreeIndex = getRandomTreeIndex()
        addTreeBlip(currentTreeIndex)
        createSellNPC()
        createSellBlip()
    end
end)

Citizen.CreateThread(function()
    while playerJob == nil do
        Citizen.Wait(1000)
    end

    if playerJob == 'bucheron' then
        while true do
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToSellPoint = GetDistanceBetweenCoords(playerCoords, sellPoint.x, sellPoint.y, sellPoint.z, true)

            if distanceToSellPoint < 2.5 then
                if not isNearSellPoint then
                    isNearSellPoint = true
                    ESX.TriggerServerCallback('bucheron:getWoodCount', function(count)
                        woodCount = count
                        if woodCount > 0 then
                            ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre le bois")
                        else
                            ESX.ShowHelpNotification("Vous n'avez pas de bois")
                        end
                    end)
                end

                if IsControlJustReleased(0, 38) then
                    OpenSellMenu()
                end
            else
                isNearSellPoint = false
            end
        end
    end
end)

Citizen.CreateThread(function()
    while playerJob == nil do
        Citizen.Wait(1000)
    end

    if playerJob == 'bucheron' then
        while true do
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local tree = treeCoords[currentTreeIndex]
            local distanceToTree = GetDistanceBetweenCoords(playerCoords, tree.x, tree.y, tree.z, true)

            if distanceToTree < 12.5 then
                DrawMarker(21, tree.x, tree.y, tree.z - 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour couper l'arbre")
                
                if distanceToTree < 1.5 then
                    if IsControlJustReleased(0, 38) then
                        if not isCutting then
                            cutTree()
                        else
                            ESX.ShowNotification("Vous êtes déjà en train de couper un arbre")
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('bucheron:giveWood')
AddEventHandler('bucheron:giveWood', function()
    if hasCutTree then
        hasCutTree = false
        TriggerServerEvent('bucheron:giveWoodToPlayer')
    else
        TriggerServerEvent('bucheron:reportCheater', 'Tentative de triche lors de la coupe du bois')
    end
end)

RegisterNetEvent('bucheron:woodSold')
AddEventHandler('bucheron:woodSold', function(count)
    ESX.ShowNotification("Vous avez vendu " .. count .. " bois")
end)

AddEventHandler('playerSpawned', function()
    getPlayerJob()
end)
