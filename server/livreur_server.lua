ESX.RegisterServerCallback('delivery:reward', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addMoney(500)
        cb(true)
    else
        cb(false)
    end
end)
