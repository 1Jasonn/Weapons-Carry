local PlayerSlungWeapons = {}


local function EnsurePlayerTable(src)
    if not PlayerSlungWeapons[src] then
        PlayerSlungWeapons[src] = {}
    end
end


RegisterNetEvent("sling:server:syncWeapon", function(weaponHash, state)
    local src = source
    if not src then return end

    EnsurePlayerTable(src)

    if state then

        if not PlayerSlungWeapons[src][weaponHash] then
            PlayerSlungWeapons[src][weaponHash] = true

     
            TriggerClientEvent("sling:client:updateWeapon", -1, src, weaponHash, true)
        end
    else
    
        if PlayerSlungWeapons[src][weaponHash] then
            PlayerSlungWeapons[src][weaponHash] = nil

        
            TriggerClientEvent("sling:client:updateWeapon", -1, src, weaponHash, false)
        end
    end
end)


RegisterNetEvent("sling:server:requestSync", function()
    local src = source
    if not src then return end

    for playerId, weapons in pairs(PlayerSlungWeapons) do
        for weaponHash, _ in pairs(weapons) do
            TriggerClientEvent("sling:client:updateWeapon", src, playerId, weaponHash, true)
        end
    end
end)


AddEventHandler("playerJoining", function()
    local src = source
    if not src then return end

    for playerId, weapons in pairs(PlayerSlungWeapons) do
        for weaponHash, _ in pairs(weapons) do
            TriggerClientEvent("sling:client:updateWeapon", src, playerId, weaponHash, true)
        end
    end
end)


AddEventHandler("playerDropped", function()
    local src = source
    if not src then return end

    if PlayerSlungWeapons[src] then
        for weaponHash, _ in pairs(PlayerSlungWeapons[src]) do
            TriggerClientEvent("sling:client:updateWeapon", -1, src, weaponHash, false)
        end

        PlayerSlungWeapons[src] = nil
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src, weapons in pairs(PlayerSlungWeapons) do
        for weaponHash, _ in pairs(weapons) do
            TriggerClientEvent("sling:client:updateWeapon", -1, src, weaponHash, false)
        end
    end

PlayerSlungWeapons = {}
end)
