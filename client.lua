local waitTime = 3000
local combatlog = true
local ghostPeds = {}
local drawDatas = nil

function DrawText3D(text, coords, scale)
	SetDrawOrigin(coords)
	SetTextScale(scale, scale)
	SetTextFont(0)
	SetTextWrap(0.0, 1.0)
	SetTextOutline()
	SetTextCentre(1)
	BeginTextCommandDisplayText("STRING")
	AddTextComponentString(text)
	EndTextCommandDisplayText(0, 0)
	ClearDrawOrigin()
end

AddEventHandler('playerSpawned', function()
    local playerPed = PlayerPedId()
    local pedComponents = {}

    for i = 0, 11 do
        pedComponents[i] = {
            drawable = GetPedDrawableVariation(playerPed, i),
            texture = GetPedTextureVariation(playerPed, i),
            palette = GetPedPaletteVariation(playerPed, i)
        }
    end

    TriggerServerEvent('combatlog:storePedData', GetEntityModel(playerPed), pedComponents)
end)

RegisterNetEvent('combatlog:spawnGhost')
AddEventHandler('combatlog:spawnGhost', function(playerId, identifier, model, coords, components, reason, playerName, heading)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    local ghostPed = CreatePed(4, model, coords + vector3(0.0, 0.0, -0.5), heading, false, false)
    SetEntityAlpha(ghostPed, Config.pedOpacity, false)
    SetEntityInvincible(ghostPed, true)
    SetBlockingOfNonTemporaryEvents(ghostPed, true)

    for i = 0, 11 do
        SetPedComponentVariation(ghostPed, i, components[i].drawable, components[i].texture, components[i].palette)
    end
    
    ghostPeds[identifier] = {ped = ghostPed, coords = coords, reason = reason, identifier = identifier, playerName = playerName, playerId = playerId, visible = false}
    SetEntityCollision(ghostPed, true, false)
    Wait(1000)
    SetEntityCollision(ghostPed, false, false)
    FreezeEntityPosition(ghostPed, true)
    SetPedCanBeTargetted(ghostPed, false)
end)

RegisterNetEvent('combatlog:deSpawnGhost')
AddEventHandler('combatlog:deSpawnGhost', function(identifier)
    if ghostPeds[identifier] ~= nil then
        if drawDatas ~= nil then 
            if drawDatas.playerId == ghostPeds[identifier].playerId then 
                drawDatas = nil
            end
        end
        DeleteEntity(ghostPeds[identifier].ped)
        ghostPeds[identifier] = nil
    end
end)

CreateThread(function()
    while true do
        if combatlog then
            waitTime = 3000
            for identifier, datas in pairs(ghostPeds) do
                local dist = #(GetEntityCoords(GetPlayerPed(-1)) - datas.coords)
                if dist < Config.distance then
                    if not datas.visible then 
                        datas.visible = true
                        SetEntityAlpha(datas.ped, 76, false)
                        drawDatas = {
                            playerId = datas.playerId,
                            coords = datas.coords,
                            playerName = datas.playerName,
                            reason = datas.reason,
                            identifier = datas.identifier,
                        }
                    end
                    waitTime = 1000
                else
                    if datas.visible then 
                        datas.visible = false
                        SetEntityAlpha(datas.ped, 0, false)
                        drawDatas = nil
                    end
                end
            end
        end

        Wait(waitTime)
    end
end)

CreateThread(function()
    while true do 
        if drawDatas ~= nil then
            local dist = #(GetEntityCoords(GetPlayerPed(-1)) - drawDatas.coords)
            local scale = 0.23 - dist/ Config.distance
            scale = math.max(0.23, scale)
            local text = ("~g~ID: ~w~%s  ~g~Name: ~w~%s  ~g~Reason: ~w~%s\n~g~License: ~w~%s"):format(drawDatas.playerId, drawDatas.playerName, drawDatas.reason, drawDatas.identifier)
            DrawText3D(text, drawDatas.coords + vector3(0.0, 0.0, Config.textHeight), scale)
        end

        Wait(0)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end

    for identifier, datas in pairs(ghostPeds) do 
        DeleteEntity(datas.ped)
    end
end)
  
RegisterCommand(Config.commandName, function()
    combatlog = not combatlog

    if combatlog then 
        for identifier, datas in pairs(ghostPeds) do
            datas.visible = true
            SetEntityAlpha(datas.ped, 76, false)
        end
    else
        for identifier, datas in pairs(ghostPeds) do
            datas.visible = false
            SetEntityAlpha(datas.ped, 0, false)
        end
    end
end)