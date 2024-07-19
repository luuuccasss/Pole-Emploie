local ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('poleemploi:getJobs', function(source, cb)
    MySQL.query('SELECT DISTINCT name, label FROM jobs', {}, function(result)
        local jobs = {}
        for i = 1, #result, 1 do
            table.insert(jobs, {
                name = result[i].name,
                label = result[i].label
            })
        end
        cb(jobs)
    end)
end)

RegisterServerEvent('poleemploi:setJob')
AddEventHandler('poleemploi:setJob', function(jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        if type(jobName) == 'string' then
            xPlayer.setJob(jobName, 0)
        else
            print("Error: jobName is not a string, it's a " .. type(jobName))
        end
    else
        print("Error: xPlayer is nil for source: " .. tostring(source))
    end
end)
