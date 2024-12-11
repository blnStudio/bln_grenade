local Frameworks = {
    { name = "VORP", resource = "vorp_core" },
    { name = "RedEM", resource = "redem" },
    { name = "RedEM2023", resources = {"!redem", "redem_roleplay"} },
    { name = "QBR", resource = "qbr-core" },
    { name = "RSG", resource = "rsg-core" },
    { name = "QR", resource = "qr-core" }
}

local function DetectFramework()
    for _, framework in pairs(Frameworks) do
        if framework.resources then
            local rightFramework = true
            for _, resource in pairs(framework.resources) do
                if resource:sub(1, 1) == "!" then
                    if GetResourceState(resource:sub(2)) ~= "missing" then
                        rightFramework = false
                        break
                    end
                else
                    if GetResourceState(resource) == "missing" then
                        rightFramework = false
                        break
                    end
                end
            end
            if rightFramework then
                for _, resource in pairs(framework.resources) do
                    if resource:sub(1, 1) ~= "!" then
                        while GetResourceState(resource) ~= "started" do
                            Wait(1000)
                        end
                    end
                end
                return framework.name
            end
        else
            if GetResourceState(framework.resource) ~= "missing" then
                while GetResourceState(framework.resource) ~= "started" do
                    Wait(1000)
                end
                return framework.name
            end
        end
    end
    return nil
end

function UseGrenade(source, grenadeType)
    TriggerClientEvent(GetCurrentResourceName() .. ':c:useGrenade', source, source, grenadeType)
end

-- VORP item registration
local function RegisterVORPItems()
    for grenadeType, data in pairs(Config.Grenades) do
        exports.vorp_inventory:registerUsableItem(data.itemName, function(itemData)
            local source = itemData.source
            if exports.vorp_inventory:canCarryItems(source, 1) then
                UseGrenade(source, grenadeType)
                exports.vorp_inventory:subItem(source, data.itemName, 1)
                exports.vorp_inventory:closeInventory(source)
            end
        end)
    end
end

-- RedEM/RedEM2023 item registration
local function RegisterRedEMItems()
    for grenadeType, data in pairs(Config.Grenades) do
        AddEventHandler("RegisterUsableItem:" .. data.itemName, function(source, itemData)
            local inv = exports["redemrp_inventory"]
            local item = inv:getItem(source, data.itemName)
            if item and item.ItemAmount >= 1 then
                UseGrenade(source, grenadeType)
                item.RemoveItem(1)
                TriggerClientEvent("redemrp_inventory:closeinv", source)
            end
        end)
    end
end

-- QBR item registration
local function RegisterQBRItems(core)
    for grenadeType, data in pairs(Config.Grenades) do
        core.Functions.CreateUseableItem(data.itemName, function(source, itemData)
            local Player = core.Functions.GetPlayer(source)
            if Player.Functions.RemoveItem(data.itemName, 1) then
                UseGrenade(source, grenadeType)
                TriggerClientEvent("qbr-inventory:client:closeinv", source)
            end
        end)
    end
end

-- RSG item registration
local function RegisterRSGItems(core)
    for grenadeType, data in pairs(Config.Grenades) do
        core.Functions.CreateUseableItem(data.itemName, function(source, itemData)
            local Player = core.Functions.GetPlayer(source)
            if Player.Functions.RemoveItem(data.itemName, 1) then
                UseGrenade(source, grenadeType)
                TriggerClientEvent("rsg-inventory:client:closeInv", source)
            end
        end)
    end
end

-- QR item registration
local function RegisterQRItems(core)
    for grenadeType, data in pairs(Config.Grenades) do
        core.Functions.CreateUseableItem(data.itemName, function(source, itemData)
            local Player = core.Functions.GetPlayer(source)
            if Player.Functions.RemoveItem(data.itemName, 1) then
                UseGrenade(source, grenadeType)
                TriggerClientEvent("qb-inventory:client:closeinv", source)
            end
        end)
    end
end

-- Main initialization
CreateThread(function()
    local detectedFramework = DetectFramework()
    if not detectedFramework then
        print("No compatible framework detected!")
        return
    end

    print("Detected framework: " .. detectedFramework)

    if detectedFramework == "VORP" then
        RegisterVORPItems()
    elseif detectedFramework == "RedEM" or detectedFramework == "RedEM2023" then
        RegisterRedEMItems()
    elseif detectedFramework == "QBR" then
        local core = exports['qbr-core']:GetCoreObject()
        RegisterQBRItems(core)
    elseif detectedFramework == "RSG" then
        local core = exports['rsg-core']:GetCoreObject()
        RegisterRSGItems(core)
    elseif detectedFramework == "QR" then
        local core = exports['qr-core']:GetCoreObject()
        RegisterQRItems(core)
    end
end)