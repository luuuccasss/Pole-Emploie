local ESX = exports['es_extended']:getSharedObject()

-- Définition des points pour chaque métier et des points de spawn des véhicules
local jobPoints = {
    miner = { 
        x = -425.4182, y = -1687.3049, z = 19.0291,
        vehicleSpawn = { x = -425.4615, y = -1687.3312, z = 19.0291, heading = 158.8430 }, 
        pedCoords = { x = -432.6923, y = -1693.4253, z = 18.0070, heading = 246.6769 },
        blip = { sprite = 618, color = 5, scale = 0.9, name = "Mine" }
    },
    bucheron = { 
        x = -840.9637, y = 5401.7778, z = 34.6152,
        vehicleSpawn = { x = -833.8702, y = 5414.0840, z = 34.3829, heading = 286.4206 }, 
        pedCoords = { x = -841.8250, y = 5401.2031, z = 33.6152, heading = 298.7069 },
        blip = { sprite = 85, color = 2, scale = 0.9, name = "Bûcheron" }
    },
    livreur = { 
        x = 46.8079, y = -1749.5581, z = 29.6328,
        vehicleSpawn = { x = -9.3288, y = -1742.9580, z = 29.3029, heading = 81.0470 }, 
        pedCoords = { x = 46.8079, y = -1749.5581, z = 28.6328, heading = 55.0622 },
        blip = { sprite = 477, color = 3, scale = 0.9, name = "Livreur" }
    }
}

function ShowHelpNotification(msg)
    SetTextComponentFormat("STRING")
    AddTextComponentString(msg)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function addJobBlips()
    for job, data in pairs(jobPoints) do
        local blip = AddBlipForCoord(data.x, data.y, data.z)
        SetBlipSprite(blip, data.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, data.blip.scale)
        SetBlipColour(blip, data.blip.color)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(data.blip.name)
        EndTextCommandSetBlipName(blip)

        print("Blip created for job: " .. job .. " with name: " .. data.blip.name)
    end
end

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end
end

Citizen.CreateThread(function()
    loadModel(GetHashKey('s_m_m_dockwork_01'))
    addJobBlips()
    for job, data in pairs(jobPoints) do
        local ped = CreatePed(4, GetHashKey('s_m_m_dockwork_01'), data.pedCoords.x, data.pedCoords.y, data.pedCoords.z, data.pedCoords.heading, false, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
    end
end)


Citizen.CreateThread(function()
    Citizen.Wait(5000) 
    local blip = AddBlipForCoord(-268.0, -957.0, 31.2)
    SetBlipSprite(blip, 408)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Pôle Emploi")
    EndTextCommandSetBlipName(blip)
    
    print("Blip created for Pôle Emploi")
end)

local isInJobMenu = false
local isInService = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = GetDistanceBetweenCoords(playerCoords, -268.0, -957.0, 31.2, true)

        if distance < 1.5 then
            ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu des métiers")

            if IsControlJustReleased(0, 38) then
                openJobMenu()
            end
        end
    end
end)

RMenu.Add('poleemploi', 'main', RageUI.CreateMenu("", "~w~Choisissez un métier"))
RMenu.Add('jobs', 'f6', RageUI.CreateMenu("", "~w~Actions disponibles"))

function openJobMenu()
    local elements = {}

    ESX.TriggerServerCallback('poleemploi:getJobs', function(jobs)
        for i = 1, #jobs, 1 do
            if jobs[i].name == 'miner' or jobs[i].name == 'bucheron' or jobs[i].name == 'livreur' then
                table.insert(elements, { label = jobs[i].label, value = jobs[i].name })
            end
        end

        RageUI.Visible(RMenu:Get('poleemploi', 'main'), true)
        isInJobMenu = true

        Citizen.CreateThread(function()
            while isInJobMenu do
                Citizen.Wait(0)
                RageUI.IsVisible(RMenu:Get('poleemploi', 'main'), function()
                    for i = 1, #elements, 1 do
                        RageUI.Button(elements[i].label, nil, {}, true, {
                            onSelected = function()
                                local jobName = elements[i].value
                                if type(jobName) == 'string' then
                                    TriggerServerEvent('poleemploi:setJob', jobName)
                                    SetNewWaypoint(jobPoints[jobName].pedCoords.x, jobPoints[jobName].pedCoords.y)
                                    ESX.ShowNotification("Un point a été marqué sur votre carte pour aller au travail.")
                                    isInJobMenu = false
                                    RageUI.CloseAll()
                                else
                                    print("Error: jobName is not a string, it's a " .. type(jobName))
                                end
                            end
                        })
                    end
                end)
            end
        end)
    end)
end

local jobDescriptions = {
    miner = "En tant que mineur, votre travail consiste à extraire des minerais et les transporter.",
    bucheron = "En tant que bûcheron, vous devez couper des arbres et transporter le bois.",
    livreur = "En tant que livreur, votre mission est de livrer des colis à divers endroits."
}


RegisterNetEvent('poleemploi:openF6Menu')
AddEventHandler('poleemploi:openF6Menu', function(job)
    local elements = {}

    if jobPoints[job] then
        local jobLabel = jobPoints[job].blip.name
        local buttonText = ""

        if jobLabel == 'Mine' then
            buttonText = 'Aller à la mine'
        elseif jobLabel == 'Bûcheron' then
            buttonText = 'Aller au travail de bûcheron'
        elseif jobLabel == 'Livreur' then
            buttonText = 'Aller au travail de livreur'
        end

        table.insert(elements, { label = buttonText, value = 'go_to_job', jobLabel = jobLabel })
    end

    table.insert(elements, { label = 'Information sur le travail', value = 'job_info', jobLabel = jobLabel, description = jobDescriptions[job] or "Pas de description disponible." })

    RageUI.Visible(RMenu:Get('jobs', 'f6'), true)

    Citizen.CreateThread(function()
        while RageUI.Visible(RMenu:Get('jobs', 'f6')) do
            Citizen.Wait(0)
            RageUI.IsVisible(RMenu:Get('jobs', 'f6'), function()
                for i = 1, #elements, 1 do
                    RageUI.Button(elements[i].label, elements[i].description, {}, true, {
                        onSelected = function()
                            local selectedJobLabel = elements[i].jobLabel
                            if elements[i].value == 'go_to_job' then
                                local point = jobPoints[job]
                                if point then
                                    SetNewWaypoint(point.pedCoords.x, point.pedCoords.y)
                                    ESX.ShowNotification("Un point a été marqué sur votre carte pour aller " .. (selectedJobLabel == 'Mine' and 'à la mine.' or 'au travail de ' .. selectedJobLabel:lower() .. '.'))
                                else
                                    ESX.ShowNotification("Aucun point défini pour ce travail.")
                                end
                                RageUI.CloseAll()
                            elseif elements[i].value == 'job_info' then
                                ESX.ShowNotification("Information: " .. job)
                            end
                        end
                    })
                end
            end)
        end
    end)
end)


RegisterNetEvent('poleemploi:takeService')
AddEventHandler('poleemploi:takeService', function(job)
    local point = jobPoints[job]
    if point then
        SetNewWaypoint(point.x, point.y)
        ESX.ShowNotification("Un point a été marqué sur votre carte pour récupérer votre véhicule.")
        if job == 'livreur' then
            StartDeliveryService()
        end
    else
        ESX.ShowNotification("Aucun point défini pour ce travail.")
    end
end)

RegisterNetEvent('poleemploi:leaveService')
AddEventHandler('poleemploi:leaveService', function(job)
    ESX.ShowNotification("Vous avez quitté le service.")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 167) then 
            local playerData = ESX.GetPlayerData()
            if playerData.job and playerData.job.name ~= 'unemployed' then
                TriggerEvent('poleemploi:openF6Menu', playerData.job.name)
            else
                ESX.ShowNotification("Vous n'avez pas de métier.")
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for job, data in pairs(jobPoints) do
            local distance = GetDistanceBetweenCoords(playerCoords, data.pedCoords.x, data.pedCoords.y, data.pedCoords.z, true)

            if distance < 1.5 then
                ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour sortir le véhicule")

                if IsControlJustReleased(0, 38) then
                    spawnJobVehicle(job)
                end
            end
        end
    end
end)

function spawnJobVehicle(job)
    local vehicleModel = job == 'miner' and 'tiptruck' or job == 'bucheron' and 'bison' or job == 'livreur' and 'boxville2'

    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Citizen.Wait(100)
    end

    local playerPed = PlayerPedId()
    local coords = jobPoints[job].vehicleSpawn
    local vehicle = CreateVehicle(vehicleModel, coords.x, coords.y, coords.z, coords.heading, true, false)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, "JOB")
end

