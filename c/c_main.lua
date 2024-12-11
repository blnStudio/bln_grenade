local EquippedGrenade = nil
local CurrentAnimation = nil
local ActiveProjectiles = {}
local AimStartTime = 0
local RemainingGrenades = 0
local CurrentGrenadeType = "grenade" -- Default grenade type

local function LoadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    return true
end

local function AttachGrenade(grenade, ped)
    AttachEntityToEntity(grenade, ped,
        GetEntityBoneIndexByName(ped, "SKEL_R_Finger33"),
        0.02, -0.02, -0.02,
        0.0, 180.0, 0.0,
        false, false, false, false, 0, true, false, false)
end

local function PlayAnimation(ped, dict, name, flag)
    if not DoesAnimDictExist(dict) then return end
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    
    TaskPlayAnim(ped, dict, name, 4.0, 4.0, -1, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end

local function DrawTimer(time, x, y, scale)
    local text = string.format("%.1f", time)
    SetTextScale(scale or 0.3, scale or 0.3)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 204, 0, 255)
    SetTextCentre(true)
    SetTextDropshadow(0, 0, 0, 0, 255)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), x, y)
    local factor = (string.len(text)) / 225
    DrawSprite("generic_textures", "shield", x, y+0.0140,0.015+ factor, 0.04, 0.1, 35, 35, 35, 190, 0)
end

local function DrawGrenadeCount()
    local dict = "itemtype_textures"
    local grenadeConfig = Config.Grenades[CurrentGrenadeType]
    if not HasStreamedTextureDictLoaded(dict) then
        RequestStreamedTextureDict(dict, false);
     else
         DrawSprite(dict, "itemtype_kit", 0.495, 0.94, 0.015, 0.027, 0.0, 255, 255, 255, 255);
     end
    SetTextScale(0.3, 0.3)
    SetTextColor(255, 255, 255, 255)
    SetTextCentre(false)
    SetTextDropshadow(0, 0, 0, 0, 255)
    DisplayText(CreateVarString(10, "LITERAL_STRING", string.format("%d/%d", RemainingGrenades, grenadeConfig.maxCount)), 0.505, 0.93)
end

local function ExplodeAtCoords(coords, grenadeType)
    local grenadeConfig = Config.Grenades[grenadeType]
    if grenadeConfig and grenadeConfig.explode then
        grenadeConfig.explode(coords)
    end
end

local function ExplodeGrenade(handle, grenadeType)
    if DoesEntityExist(handle) then
        local coords = GetEntityCoords(handle)
        TriggerServerEvent(GetCurrentResourceName() .. ':s:sync', coords, grenadeType)
        ExplodeAtCoords(coords, grenadeType)
        DeleteObject(handle)
    end
end

RegisterNetEvent(GetCurrentResourceName() .. ':c:syncExplosion')
AddEventHandler(GetCurrentResourceName() .. ':c:syncExplosion', function(sourcePlayer, coords, grenadeType)
    if sourcePlayer ~= GetPlayerServerId(PlayerId()) then
        ExplodeAtCoords(coords, grenadeType)
    end
end)

local function EquipGrenade(grenadeType)
    if EquippedGrenade then return end
    if RemainingGrenades <= 0 then return end

    local grenadeConfig = Config.Grenades[grenadeType]
    if not grenadeConfig then return end

    if not LoadModel(grenadeConfig.model) then return end

    local ped = PlayerPedId()
    local grenade = CreateObject(grenadeConfig.model, 0.0, 0.0, 0.0, true, false, true, false, false)
    
    SetEntityLodDist(grenade, 0xFFFF)
    AttachGrenade(grenade, ped)

    EquippedGrenade = { 
        handle = grenade,
        type = grenadeType
    }
    SetPlayerLockon(PlayerId(), false)
end

local function UnequipGrenade()
    if not EquippedGrenade then return end

    DeleteObject(EquippedGrenade.handle)
    
    if CurrentAnimation then
        StopAnimTask(PlayerPedId(), "mech_weapons_thrown@base", CurrentAnimation, 1.0)
    end

    EquippedGrenade = nil
    CurrentAnimation = nil
    SetPlayerLockon(PlayerId(), true)
end

CreateThread(function()
    while true do
        if RemainingGrenades > 0 then
            DrawGrenadeCount()
        end

        if EquippedGrenade then
            for _, control in ipairs({
                `INPUT_MELEE_ATTACK`, `INPUT_MELEE_GRAPPLE`, 
                `INPUT_MELEE_GRAPPLE_CHOKE`, `INPUT_INSPECT_ZOOM`,
                `INPUT_INTERACT_LOCKON`, `INPUT_CONTEXT_LT`
            }) do
                DisableControlAction(0, control, true)
            end

            local _, wep = GetCurrentPedWeapon(PlayerPedId())
            if wep ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true, 0, false, false)
            end

            if IsControlJustPressed(0, `INPUT_OPEN_WHEEL_MENU`) or 
               IsControlJustPressed(0, `INPUT_TOGGLE_HOLSTER`) or 
               IsControlJustPressed(0, `INPUT_TWIRL_PISTOL`) then
                UnequipGrenade()
            end
        elseif RemainingGrenades > 0 and not EquippedGrenade then
            EquipGrenade(CurrentGrenadeType)
        end
        Wait(0)
    end
end)

CreateThread(function()
    local timeStartedPressing
    local BASE_DICT = "mech_weapons_thrown@base"

    while true do
        if EquippedGrenade then
            local ped = PlayerPedId()
            local grenadeConfig = Config.Grenades[EquippedGrenade.type]

            if not IsEntityAttachedToEntity(EquippedGrenade.handle, ped) then
                AttachGrenade(EquippedGrenade.handle, ped)
            end

            if CurrentAnimation and not IsEntityPlayingAnim(ped, BASE_DICT, CurrentAnimation, 25) then
                PlayAnimation(ped, BASE_DICT, CurrentAnimation, 25)
            end

            if IsControlPressed(0, `INPUT_AIM`) and not (IsPedRagdoll(ped) or IsPedClimbing(ped)) then
                if AimStartTime == 0 then AimStartTime = GetGameTimer() end
                
                local timeHoldingAim = (GetGameTimer() - AimStartTime) / 1000
                if timeHoldingAim <= grenadeConfig.fuseTime then
                    DrawTimer(grenadeConfig.fuseTime - timeHoldingAim, 0.5, 0.5, 0.4)
                else
                    ExplodeGrenade(EquippedGrenade.handle, EquippedGrenade.type)
                    UnequipGrenade()
                    RemainingGrenades = RemainingGrenades - 1
                    AimStartTime = 0
                    goto continue
                end

                local timePressed = timeStartedPressing and (GetSystemTime() - timeStartedPressing) or 0
                local rot = GetGameplayCamRot(2)
                local zangle

                if rot.x < -20.0 then
                    CurrentAnimation = timePressed > 1000 and "aimlive_l" or "aim_l"
                    zangle = 5.0
                elseif rot.x < 20.0 then
                    CurrentAnimation = timePressed > 1000 and "aimlive_m" or "aim_m"
                    zangle = 10.0
                else
                    CurrentAnimation = timePressed > 1000 and "aimlive_h" or "aim_h"
                    zangle = 15.0
                end

                if IsControlPressed(0, `INPUT_ATTACK`) then
                    if not timeStartedPressing then timeStartedPressing = GetSystemTime() end
                elseif IsControlJustReleased(0, `INPUT_ATTACK`) then
                    local velocity = Config.BaseVelocity * (timePressed > 1000 and 5 or timePressed > 200 and 3 or 1)
                    local throwAnim = timePressed > 1000 and "throw_h_fb_stand" or timePressed > 200 and "throw_m_fb_stand" or "throw_l_fb_stand"

                    timeStartedPressing = nil
                    
                    ClearPedTasksImmediately(ped)
                    SetEntityHeading(ped, rot.z)
                    PlayAnimation(ped, BASE_DICT, throwAnim, 2)
                    Wait(500)

                    local r = math.rad(-rot.z)
                    local vx = velocity * math.sin(r)
                    local vy = velocity * math.cos(r)
                    local vz = rot.x + zangle

                    local grenadeHandle = EquippedGrenade.handle
                    local grenadeType = EquippedGrenade.type
                    
                    ClearPedTasks(ped)
                    DetachEntity(grenadeHandle, true, true)
                    SetEntityCoords(grenadeHandle, GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.2))
                    SetEntityVelocity(grenadeHandle, vx, vy, vz)

                    local remainingTime = grenadeConfig.fuseTime - ((GetGameTimer() - AimStartTime) / 1000)
                    if remainingTime > 0 then
                        ActiveProjectiles[grenadeHandle] = {
                            explodeTime = GetGameTimer() + (remainingTime * 1000),
                            remainingTime = remainingTime,
                            type = grenadeType
                        }
                    else
                        ExplodeGrenade(grenadeHandle, grenadeType)
                    end

                    RemainingGrenades = RemainingGrenades - 1
                    AimStartTime = 0
                    EquippedGrenade = nil
                end
            else
                AimStartTime = 0
                timeStartedPressing = nil
                CurrentAnimation = IsPedWalking(ped) and "walk" or "idle"
            end
        end
        ::continue::
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        
        local hasProjectiles = false
        for handle, data in pairs(ActiveProjectiles) do
            hasProjectiles = true
            if DoesEntityExist(handle) then
                local currentTime = GetGameTimer()
                if currentTime < data.explodeTime then
                    local timeLeft = (data.explodeTime - currentTime) / 1000
                    local coords = GetEntityCoords(handle)
                    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
                    if onScreen then
                        DrawTimer(timeLeft, x, y - 0.05)
                    end
                else
                    ExplodeGrenade(handle, data.type)
                    ActiveProjectiles[handle] = nil
                end
            else
                ActiveProjectiles[handle] = nil
            end
        end
        
        Wait(hasProjectiles and 0 or 250)
    end
end)

RegisterNetEvent(GetCurrentResourceName() .. ':c:useGrenade')
AddEventHandler(GetCurrentResourceName() .. ':c:useGrenade', function(sourcePlayer, grenadeType)
    if sourcePlayer == GetPlayerServerId(PlayerId()) then
        if EquippedGrenade then
            UnequipGrenade()
            RemainingGrenades = 0
        else
            if Config.Grenades[grenadeType] then
                CurrentGrenadeType = grenadeType
                RemainingGrenades = Config.Grenades[grenadeType].maxCount
                EquipGrenade(grenadeType)
            end
        end
    end
end)

CreateThread(function()
    local isDead = false
    while true do
        local ped = PlayerPedId()
        local currentDeadState = IsEntityDead(ped)
        
        if currentDeadState and not isDead then
            Cleanup()
            RemainingGrenades = 0
        end
        
        isDead = currentDeadState
        Wait(500)
    end
end)

function Cleanup()
    if EquippedGrenade then 
        UnequipGrenade() 
    end
    
    for handle in pairs(ActiveProjectiles) do
        if DoesEntityExist(handle) then 
            DeleteObject(handle) 
        end
    end
    ActiveProjectiles = {}
    
    CurrentAnimation = nil
    AimStartTime = 0
    
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    
    for _, control in ipairs({
        `INPUT_MELEE_ATTACK`, `INPUT_MELEE_GRAPPLE`, 
        `INPUT_MELEE_GRAPPLE_CHOKE`, `INPUT_INSPECT_ZOOM`,
        `INPUT_INTERACT_LOCKON`, `INPUT_CONTEXT_LT`
    }) do
        EnableControlAction(0, control, true)
    end
    
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    SetPlayerLockon(PlayerId(), true)
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Cleanup()
    
end)