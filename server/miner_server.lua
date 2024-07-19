local ESX = exports['es_extended']:getSharedObject()

local function sendNotification(playerId, message)
    TriggerClientEvent('miner:notify', playerId, message)
end

local function kickPlayer(playerId, reason)
    DropPlayer(playerId, reason)
end

local function isPlayerMiner(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer and xPlayer.job and xPlayer.job.name == 'miner' then
        return true
    end
    return false
end

local playerActionsCooldown = {}
local spamThreshold = 1 
local spamCooldownTime = 1

local function isPlayerSpamming(playerId, action)
    local currentTime = os.clock()
    if not playerActionsCooldown[playerId] then
        playerActionsCooldown[playerId] = {}
    end

    if not playerActionsCooldown[playerId][action] then
        playerActionsCooldown[playerId][action] = { count = 0, lastTime = currentTime }
    end

    local cooldownData = playerActionsCooldown[playerId][action]

    if currentTime - cooldownData.lastTime < spamCooldownTime then
        cooldownData.count = cooldownData.count + 1
    else
        cooldownData.count = 1
    end

    cooldownData.lastTime = currentTime

    if cooldownData.count > spamThreshold then
        return true
    end

    return false
end

RegisterServerEvent('miner:startMining')
AddEventHandler('miner:startMining', function()
    local _source = source
    if isPlayerMiner(_source) then
        if isPlayerSpamming(_source, 'startMining') then
            kickPlayer(_source, "Expulsé pour tentative de spam minage.")
            return
        end
        TriggerClientEvent('miner:playMiningAnimation', _source)
        Citizen.Wait(2000) 
        TriggerEvent('miner:completeMining', _source)
    else
        kickPlayer(_source, "Tentative non autorisée d'utilisation du minage.")
    end
end)

RegisterServerEvent('miner:completeMining')
AddEventHandler('miner:completeMining', function(_source)
    if isPlayerMiner(_source) then
        local xPlayer = ESX.GetPlayerFromId(_source)
        if xPlayer then
            xPlayer.addInventoryItem('raw_mineral', 1)
            sendNotification(_source, "Vous avez miné un minéral brut.")
        else
            print("Error: xPlayer is nil for source " .. tostring(_source))
        end
    else
        kickPlayer(_source, "Tentative non autorisée d'utilisation du minage.")
    end
end)

RegisterServerEvent('miner:startProcessing')
AddEventHandler('miner:startProcessing', function()
    local _source = source
    if isPlayerMiner(_source) then
        if isPlayerSpamming(_source, 'startProcessing') then
            kickPlayer(_source, "Expulsé pour tentative de spam traitement.")
            return
        end
        local xPlayer = ESX.GetPlayerFromId(_source)
        if xPlayer then
            local rawMinerals = xPlayer.getInventoryItem('raw_mineral').count
            if rawMinerals > 0 then
                xPlayer.removeInventoryItem('raw_mineral', 1)
                sendNotification(_source, "Traitement en cours...")
                TriggerClientEvent('miner:playProcessingAnimation', _source)
                Citizen.Wait(5000) 
                xPlayer.addInventoryItem('processed_mineral', 1)
                sendNotification(_source, "Vous avez traité un minéral.")
                TriggerClientEvent('miner:processingComplete', _source)
            else
                sendNotification(_source, "Vous n'avez pas de minéraux à traiter.")
                TriggerClientEvent('miner:processingComplete', _source)
            end
        else
            print("Error: xPlayer is nil for source " .. tostring(_source))
            TriggerClientEvent('miner:processingComplete', _source)
        end
    else
        kickPlayer(_source, "Tentative non autorisée d'utilisation du traitement.")
    end
end)

RegisterServerEvent('miner:startSelling')
AddEventHandler('miner:startSelling', function()
    local _source = source
    if isPlayerMiner(_source) then
        if isPlayerSpamming(_source, 'startSelling') then
            kickPlayer(_source, "Expulsé pour tentative de spam vente.")
            return
        end
        local xPlayer = ESX.GetPlayerFromId(_source)
        if xPlayer then
            local processedMinerals = xPlayer.getInventoryItem('processed_mineral').count
            if processedMinerals > 0 then
                xPlayer.removeInventoryItem('processed_mineral', 1)
                local payment = math.random(75, 200)
                xPlayer.addMoney(payment)
                sendNotification(_source, "Vous avez vendu un minéral traité pour $" .. payment)
                TriggerClientEvent('miner:playSellingAnimation', _source)
                Citizen.Wait(2000)
                TriggerClientEvent('miner:sellingComplete', _source)
            else
                sendNotification(_source, "Vous n'avez pas de minéraux à vendre.")
                TriggerClientEvent('miner:sellingComplete', _source)
            end
        else
            print("Error: xPlayer is nil for source " .. tostring(_source))
            TriggerClientEvent('miner:sellingComplete', _source)
        end
    else
        kickPlayer(_source, "Tentative non autorisée d'utilisation de la vente.")
    end
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    playerActionsCooldown[_source] = nil
end)
