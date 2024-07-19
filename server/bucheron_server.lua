local ESX = exports['es_extended']:getSharedObject()

local lastSellTime = {}

RegisterServerEvent('bucheron:giveWoodToPlayer')
AddEventHandler('bucheron:giveWoodToPlayer', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        xPlayer.addInventoryItem('wood', 1)
        TriggerClientEvent('esx:showNotification', source, 'Vous avez reçu du bois')
    else
        print(('bucheron:giveWoodToPlayer: %s non trouvé'):format(source))
    end
end)

RegisterServerEvent('bucheron:sellWood')
AddEventHandler('bucheron:sellWood', function(count)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local currentTime = os.time()
    
    count = tonumber(count)
    
    if not count or count <= 0 or count ~= math.floor(count) then
        print(('bucheron:sellWood: Tentative de triche détectée par %s avec count invalide: %s'):format(source, tostring(count)))
        DropPlayer(source, "Tentative de triche détectée")
        return
    end

    if lastSellTime[source] and (currentTime - lastSellTime[source]) < 5 then
        print(('bucheron:sellWood: Tentative de triche détectée par %s avec ventes fréquentes (time diff: %s)'):format(source, currentTime - lastSellTime[source]))
        DropPlayer(source, "Tentative de triche détectée")
        return
    end

    if xPlayer then
        local woodCount = xPlayer.getInventoryItem('wood').count

        if woodCount >= count then
            xPlayer.removeInventoryItem('wood', count)
            xPlayer.addMoney(250 * count)
            lastSellTime[source] = currentTime
            TriggerClientEvent('bucheron:woodSold', source, count)
        else
            TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas assez de bois")
        end
    else
        print(('bucheron:sellWood: %s non trouvé'):format(source))
    end
end)

ESX.RegisterServerCallback('bucheron:getWoodCount', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local woodCount = xPlayer.getInventoryItem('wood').count
        cb(woodCount)
    else
        cb(0)
    end
end)

RegisterServerEvent('bucheron:reportCheater')
AddEventHandler('bucheron:reportCheater', function(message)
    local source = source
    print(('bucheron:reportCheater: %s - %s'):format(source, message))
    DropPlayer(source, message)
end)
