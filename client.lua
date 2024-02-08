local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('AntiF8:client:OpenInventoryMenu', function(inventory, citizenid)
    local menuItems = {
        {
            header = "Quitter\'s Inventory | " .. citizenid,
            isMenuHeader = true,
        }
    }

    for i, item in pairs(inventory) do
        if item then
            local itemInfo = QBCore.Shared.Items[item.name:lower()]
            if itemInfo then
                local itemLabel = itemInfo['label'] or "Unknown Item"
                local itemDescription = itemInfo['description'] or "No description"
                local itemAmount = item.amount or 1

                if itemInfo['type'] == 'weapon' and item.info then
                    itemDescription = ""  
                    if item.info.ammo then
                        itemDescription = "Ammo: " .. item.info.ammo
                    end
                    if item.info.quality then
                        itemDescription = (itemDescription ~= "" and itemDescription .. " | " or "") .. "Quality: " .. string.format("%.f", item.info.quality)
                    end

                end

                table.insert(menuItems, {
                    header = itemLabel,
                    txt = itemDescription .. " | Amount: " .. itemAmount,
                    params = {
                        event = 'AntiF8:client:TakeItem',
                        args = {
                            item = {
                                name = itemInfo['name'],
                                amount = itemAmount,
                                info = item.info or '',
                                label = itemLabel,
                                description = itemDescription,
                                weight = itemInfo['weight'],
                                type = itemInfo['type'],
                                unique = itemInfo['unique'],
                                useable = itemInfo['useable'],
                                image = itemInfo['image'],
                                shouldClose = itemInfo['shouldClose'],
                                slot = item.slot,
                                combinable = itemInfo['combinable'],
                                created = item.created,
                            },
                            citizenid = citizenid
                        }
                    }
                })
            end
        end
    end

    exports['qb-menu']:openMenu(menuItems)
end)

RegisterNetEvent('AntiF8:client:TakeItem', function(data)
    local item = data.item
    local citizenid = data.citizenid
    local playerServerId = GetPlayerServerId(PlayerId())
    TriggerServerEvent('AntiF8:server:RemoveItemFromPlayerAddItemToLooter', playerServerId, citizenid, item)
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(Config.TextColor[1], Config.TextColor[2], Config.TextColor[3], Config.TextColor[4])
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

RegisterNetEvent('AntiF8:client:ShowDeadPlayerPopup')
AddEventHandler('AntiF8:client:ShowDeadPlayerPopup', function(coords, citizenid)
    local playerCoords = coords
    local endTime = GetGameTimer() + (Config.LootOptionTime * 1000)

    Citizen.CreateThread(function()
        while GetGameTimer() < endTime do
            Citizen.Wait(0)
            local currentTime = GetGameTimer()
            local remainingTime = math.ceil((endTime - currentTime) / 1000)

            if #(GetEntityCoords(PlayerPedId()) - playerCoords) < 20 then
                local text = Config.LootText
                if Config.ShowTimerInText then
                    text = text .. " (" .. remainingTime .. "s)"
                end
                DrawText3D(playerCoords.x, playerCoords.y, playerCoords.z - 1, text, Config.TextColor)
                if IsControlJustReleased(0, Config.LootKeybind) then
                    local playerId = GetPlayerServerId(PlayerId())
                    TriggerServerEvent('AntiF8:server:OpenDeadPlayerInventory', citizenid, playerId)
                end
            end
        end
    end)
end)
