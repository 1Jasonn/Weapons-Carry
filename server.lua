

local attachedWeapons = {}
local attachedComponents = {}
local cachedWeapon = nilW
local playerPed = PlayerPedId()


local function HasItem(itemName)
    if GetResourceState("ox_inventory") == "started" then
        local count = exports.ox_inventory:GetItemCount(itemName)
        return (count or 0) > 0
    end
    return false
end


local function DeleteLocalEntity(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end


local function GetWeaponModel(weaponData, weaponHash)
    if weaponData.model then
        return weaponData.model
    end
    
    if GetResourceState("ox_inventory") == "started" then
        local itemData = exports.ox_inventory:Items(weaponData.itemName)
        if itemData and itemData.model then
            return itemData.model
        end
    end
    
    return weaponData.itemName
end


function AttachWeapon(attachModel, modelHash, itemName, boneNumber, x, y, z, xR, yR, zR)
    playerPed = PlayerPedId()
    local bone = GetPedBoneIndex(playerPed, boneNumber)
    local modelHashKey = GetHashKey(attachModel)

    if not HasModelLoaded(modelHashKey) then
        RequestModel(modelHashKey)
        local timeout = 0
        while not HasModelLoaded(modelHashKey) do
            Wait(0)
            timeout = timeout + 1
            if timeout > 50 then return end
        end
    end

    local weaponObject = CreateObject(modelHashKey, 1.0, 1.0, 1.0, true, true, false)
    if not weaponObject or weaponObject == 0 then return end


    local weaponComponents = {}
    if GetResourceState("ox_inventory") == "started" then
        local weaponSlot = exports.ox_inventory:GetSlotWithItem(itemName) or exports.ox_inventory:GetSlotWithItem(itemName:upper())
        if weaponSlot and weaponSlot.metadata and weaponSlot.metadata.components then
            if type(weaponSlot.metadata.components) == 'table' then
                local isArray = true
                for k in pairs(weaponSlot.metadata.components) do
                    if type(k) ~= 'number' then isArray = false break end
                end
                if isArray then
                    weaponComponents = weaponSlot.metadata.components
                else
                    for _, componentName in pairs(weaponSlot.metadata.components) do
                        if componentName and type(componentName) == 'string' then
                            table.insert(weaponComponents, componentName)
                        end
                    end
                end
            end
        end
    end


    attachedComponents[modelHash] = {}
    local weaponComponentConfig = Config.SlingWeaponComponents[itemName:upper()] or Config.SlingWeaponComponents[itemName]
    if weaponComponentConfig then
        for componentName, componentModel in pairs(weaponComponentConfig) do
            if componentModel then
                local componentHash = componentModel
                if not HasModelLoaded(componentHash) then
                    RequestModel(componentHash)
                    local timeout = 0
                    while not HasModelLoaded(componentHash) do
                        Wait(0)
                        timeout = timeout + 1
                        if timeout > 100 then break end
                    end
                end
                if HasModelLoaded(componentHash) then
                    local componentObject = CreateObject(componentHash, 1.0, 1.0, 1.0, true, true, false)
                    if componentObject and componentObject ~= 0 then
                        AttachEntityToEntity(componentObject, weaponObject, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 0, true)
                        table.insert(attachedComponents[modelHash], componentObject)
                        SetModelAsNoLongerNeeded(componentHash)
                    end
                end
            end
        end
    end

    attachedWeapons[modelHash] = {
        hash = modelHash,
        item = itemName,
        handle = weaponObject
    }

    AttachEntityToEntity(weaponObject, playerPed, bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
    SetModelAsNoLongerNeeded(modelHashKey)


    TriggerServerEvent("sling:server:syncWeapon", modelHash, true)
end

local function UpdateBackItems()
    playerPed = PlayerPedId()

    for weaponHash, weaponData in pairs(Config.SlingCompatibleWeapons) do
        if HasItem(weaponData.itemName) then
            if not attachedWeapons[weaponHash] and GetSelectedPedWeapon(playerPed) ~= weaponHash then
                local weaponModel = GetWeaponModel(weaponData, weaponHash)
                AttachWeapon(weaponModel, weaponHash, weaponData.itemName, weaponData.bone, weaponData.x, weaponData.y, weaponData.z, weaponData.rotX, weaponData.rotY, weaponData.rotZ)
            end
        else
            if attachedWeapons[weaponHash] then
                DeleteLocalEntity(attachedWeapons[weaponHash].handle)
                if attachedComponents[weaponHash] then
                    for _, componentHandle in pairs(attachedComponents[weaponHash]) do
                        DeleteLocalEntity(componentHandle)
                    end
                    attachedComponents[weaponHash] = nil
                end

   
                TriggerServerEvent("sling:server:syncWeapon", weaponHash, false)

                attachedWeapons[weaponHash] = nil
            end
        end
    end
end

CreateThread(function()
    while true do
        UpdateBackItems()
        Wait(1000)
    end
end)


AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for k, v in pairs(attachedWeapons) do
            DeleteLocalEntity(v.handle)
            if attachedComponents[k] then
                for _, componentHandle in pairs(attachedComponents[k]) do
                    DeleteLocalEntity(componentHandle)
                end
                attachedComponents[k] = nil
            end
            attachedWeapons[k] = nil
        end
    end
end)