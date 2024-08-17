local playerPedData = {}
local droppedDatas = {}

function sendToDiscord(color, playerName, reason, identifier)
    local embed = {
        {
            ["color"] = color,
            ["title"] = ("Player (%s) left the game"):format(playerName),
            ["fields"] = {
                {
                    name = "PlayerName",
                    value = "**"..playerName.."**",
                    inline = false,
                },
                {
                    name = "Time",
                    value = "**" .. os.date("%H") .. "** : **" .. os.date("%M") .. "**",
                    inline = false,
                },
                { 
                    name = "Reason", 
                    value = reason, 
                    inline = false
                },
                { 
                    name = "Identifier", 
                    value = "```" .. identifier .. "```", 
                    inline = false
                },
            }
        },
    }
    
    PerformHttpRequest(Config.webhook, function(err, text, headers) end,
        "POST",
        json.encode({
            username = "Fivem Combatlog",
            embeds = embed,
        }),
        { ["Content-Type"] = "application/json" }
    )
end

RegisterNetEvent('combatlog:storePedData')
AddEventHandler('combatlog:storePedData', function(model, components)
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)

    playerPedData[identifier] = {
        model = model,
        components = components,
    }
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local playerName = GetPlayerName(playerId)
    local identifier = GetPlayerIdentifier(playerId)

    if playerPedData[identifier] then
        local pedData = playerPedData[identifier]
        local ped = GetPlayerPed(playerId)

        TriggerClientEvent('combatlog:spawnGhost', -1, playerId, identifier, pedData.model, GetEntityCoords(ped), pedData.components, reason, playerName, GetEntityHeading(ped))
        if Config.useWebhook then 
            sendToDiscord(Config.embedColor, playerName, reason, identifier)
        end

        droppedDatas[identifier] = Config.timer
        playerPedData[identifier] = nil
    
    end
end)


CreateThread(function()
    while true do 
        for identifier, timer in pairs(droppedDatas) do 
            if timer > 0 then
                droppedDatas[identifier] = timer - 5000
            else
                TriggerClientEvent('combatlog:deSpawnGhost', -1, identifier)
                droppedDatas[identifier] = nil
            end
        end
        Wait(5000)
    end
end)

function OnPlayerConnecting(name, setKickReason, deferrals)
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    TriggerClientEvent('combatlog:deSpawnGhost', -1, identifier)
end

AddEventHandler("playerConnecting", OnPlayerConnecting)