local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add("seeinv", "See a player's inventory", {{name="citizenid", help="Citizen ID of the player"}}, true, function(source, args)
    local citizenid = args[1]
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', source, 'You must provide a Citizen ID', 'error')
        return
    end

    local result = MySQL.Sync.fetchAll('SELECT inventory FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    })

    if result and result[1] then
        local inventory = json.decode(result[1].inventory)
        TriggerClientEvent('AntiF8:client:OpenInventoryMenu', source, inventory, citizenid)
    else
        TriggerClientEvent('QBCore:Notify', source, 'No player found with that Citizen ID', 'error')
    end
end, 'admin')

RegisterNetEvent('AntiF8:server:RemoveItemFromPlayerAddItemToLooter')
AddEventHandler('AntiF8:server:RemoveItemFromPlayerAddItemToLooter', function(playerServerId, citizenid, itemToRemove)
    if Config.DisallowLootingIfPlayerOnline then
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if targetPlayer then
            TriggerClientEvent('QBCore:Notify', playerServerId, 'Player is online and cannot be looted', 'error')
            return
        end
    end

    if Config.NonLootableItems[itemToRemove.name] then
        TriggerClientEvent('QBCore:Notify', playerServerId, 'This item cannot be looted', 'error')
        return
    end

    local result = MySQL.Sync.fetchAll('SELECT inventory FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    })

    if not result or not result[1] then
        TriggerClientEvent('QBCore:Notify', playerServerId, 'No player found with that Citizen ID', 'error')
        return
    end

    local inventory = json.decode(result[1].inventory)
    local itemRemoved = false

    for i, item in ipairs(inventory) do
        if item.name == itemToRemove.name and item.slot == itemToRemove.slot then
            table.remove(inventory, i)
            itemRemoved = true
            break
        end
    end

    if not itemRemoved then
        TriggerClientEvent('QBCore:Notify', playerServerId, 'Item not found in inventory: ' .. citizenid .. " | item: " .. itemToRemove.name .. " x" .. itemToRemove.amount, 'error')
        return
    end

    local looter = QBCore.Functions.GetPlayer(playerServerId)
    if looter then

    if canPlayerCarryItem(looter, itemToRemove.name, itemToRemove.amount) then


            local updateResult = MySQL.Sync.execute('UPDATE players SET inventory = @inventory WHERE citizenid = @citizenid', {
                ['@inventory'] = json.encode(inventory),
                ['@citizenid'] = citizenid
            })

            if updateResult then
                looter.Functions.AddItem(itemToRemove.name, itemToRemove.amount, nil, itemToRemove.info)
                TriggerClientEvent('QBCore:Notify', playerServerId, 'Added '.. itemToRemove.name .. " x" .. itemToRemove.amount, 'success')
            else
                TriggerClientEvent('QBCore:Notify', playerServerId, 'Error updating player inventory in database', 'error')
            end
        else
        TriggerClientEvent('QBCore:Notify', playerServerId, 'Cannot carry item: ' .. itemToRemove.name, 'error')
    end
else
    TriggerClientEvent('QBCore:Notify', playerServerId, 'Error adding item to looter', 'error')
end
end)

RegisterNetEvent('AntiF8:server:OpenDeadPlayerInventory')
AddEventHandler('AntiF8:server:OpenDeadPlayerInventory', function(citizenid, playerId)
    local result = MySQL.Sync.fetchAll('SELECT inventory FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    })

    if result and result[1] then
        local inventory = json.decode(result[1].inventory)
        TriggerClientEvent('AntiF8:client:OpenInventoryMenu', playerId, inventory, citizenid)
    else
        TriggerClientEvent('QBCore:Notify', playerId, 'No player found with that Citizen ID', 'error')
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerCoords = GetEntityCoords(GetPlayerPed(src))

    local license = nil
    for k, v in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            license = v
            break
        end
    end
    Citizen.Wait(3500)
    if license then
        local result = MySQL.Sync.fetchAll('SELECT citizenid, metadata, job FROM players WHERE license = @license', {
            ['@license'] = license
        })

        if result and result[1] then
            local citizenid = result[1].citizenid
            local job = result[1].job

            local isWhitelistedJob = false
            for _, whitelistedJob in ipairs(Config.WhitelistedJobs) do
                if job == whitelistedJob then
                    isWhitelistedJob = true
                    break
                end
            end

            if Config.DontShowOptionIfPlayerHasWhitelistedJob and isWhitelistedJob then
                return
            end
            if Config.ShowLootOptionIfDead or Config.ShowLootOptionIfCuffed then
    		local metadata = json.decode(result[1].metadata)
    		local isDead = metadata.isdead or false
    		local isInLastStand = metadata.inlaststand or false
    		local isHandcuffed = metadata.ishandcuffed or false
    
    		if isDead or isInLastStand or isHandcuffed then
        		TriggerClientEvent('AntiF8:client:ShowDeadPlayerPopup', -1, playerCoords, citizenid)
    		end
	    else
    		TriggerClientEvent('AntiF8:client:ShowDeadPlayerPopup', -1, playerCoords, citizenid)
	    end
        else
            print("No player data found for " .. license .. " no loot option was given!")
        end
    else
        print("Error while trying to grab F8ers license.")
    end
end)

function canPlayerCarryItem(player, itemName, itemAmount)
    local currentWeight = 0
    local currentSlotsUsed = 0

    for _, item in pairs(player.PlayerData.items) do
        local itemInfo = QBCore.Shared.Items[item.name]
        if itemInfo then
            currentWeight = currentWeight + (itemInfo.weight * item.amount)
            currentSlotsUsed = currentSlotsUsed + 1
        end
    end

    local addItemInfo = QBCore.Shared.Items[itemName]
    if addItemInfo then
        local addItemWeight = addItemInfo.weight * itemAmount
        local canCarryWeight = (currentWeight + addItemWeight) <= Config.MaxWeight
        local hasSlotAvailable = currentSlotsUsed < Config.MaxSlots

        return canCarryWeight and hasSlotAvailable
    else
        return false
    end
end
