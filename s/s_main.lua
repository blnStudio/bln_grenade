
RegisterServerEvent(GetCurrentResourceName() .. ':s:sync')
AddEventHandler(GetCurrentResourceName() .. ':s:sync', function(coords, grenadeType)
    local _source = source
    TriggerClientEvent(GetCurrentResourceName() .. ':c:syncExplosion', -1, coords, grenadeType,  _source)
end)