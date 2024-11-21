
Citizen.CreateThread(function()
    instanceNumber = math.random(1, 100000 + tonumber(GetPlayerServerId(PlayerPedId())))
    Core.instancePlayers(tonumber(GetPlayerServerId(PlayerId())) + instanceNumber)
end)

Citizen.CreateThread(function()
    instanceNumber = math.random(1, 100000 + tonumber(GetPlayerServerId(PlayerPedId())))
    Core.instancePlayers(tonumber(GetPlayerServerId(PlayerId())) + instanceNumber)
end)

local lastPedAimed = nil
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local exists, playerWeapon = GetCurrentPedWeapon(playerPed)

        if DoesEntityExist(playerPed) and IsPedArmed(playerPed, 4) then
            local isAiming, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId())

            -- Ensure targetPed is the correct reference by checking its existence
            if isAiming and DoesEntityExist(targetPed) and targetPed ~= lastPedAimed then
                lastPedAimed = targetPed
                local weaponName = WeaponNames[tostring(playerWeapon)] or "Unknown Weapon"
                
                print("Player is aiming with weapon:", weaponName)

                if IsEntityAPed(targetPed) then
                    local isPlayer = IsPedAPlayer(targetPed)
                    
                    if isPlayer then
                        -- If the target is a player
                        local targetId = NetworkGetPlayerIndexFromPed(targetPed)
                        if targetId then
                            local pedId = GetPlayerServerId(targetId)
                            if pedId and (pedId > 0) then
                                print("Triggering player aim log event for target ID:", pedId)
                                TriggerServerEvent('bcc-logs:aimlogs', pedId)
                            end
                        end
                    else
                        -- If the target is an NPC, check if they have a weapon equipped
                        local hasWeapon, npcWeapon = GetCurrentPedWeapon(targetPed, true)
                        
                        if hasWeapon and npcWeapon ~= `WEAPON_UNARMED` then
                            local npcWeaponName = WeaponNames[tostring(npcWeapon)] or "Unknown Weapon"
                            print("NPC is equipped with weapon:", npcWeaponName)
                            print("Triggering NPC aim log event for NPC weapon:", npcWeaponName)
                            TriggerServerEvent('bcc-logs:npcAimLogs', "NPC", npcWeaponName)
                        else
                            print("NPC does not have a weapon equipped or is unarmed.")
                        end
                    end
                else
                    print("Aimed target is not a ped or entity does not exist.")
                end
            else
                if not isAiming then
                    print("Player is not currently aiming.")
                elseif targetPed == lastPedAimed then
                    print("Player is still aiming at the same target.")
                end
            end
        else
            print("Player is either not armed or player entity does not exist.")
        end
    end
end)

Citizen.CreateThread(function()
    local DeathReason, Killer, DeathCauseHash, Weapon
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()

        if IsEntityDead(playerPed) then
            Citizen.Wait(500)
            local PedKiller = GetPedSourceOfDeath(playerPed)
            DeathCauseHash = GetPedCauseOfDeath(playerPed)
            Weapon = WeaponNames[DeathCauseHash] or "Unknown Weapon"

            if IsEntityAPed(PedKiller) then
                if IsPedAPlayer(PedKiller) then
                    -- Player killer
                    Killer = NetworkGetPlayerIndexFromPed(PedKiller)
                    DeathReason = determineDeathReason(DeathCauseHash)
                    TriggerServerEvent('bcc-logs:killlogs', GetPlayerName(Killer) .. '['..GetPlayerServerId(Killer).. '] ' .. DeathReason .. ' ' .. GetPlayerName(PlayerId()) .. '['..GetPlayerServerId(PlayerId())..']', Weapon)
                else
                    -- NPC killer
                    DeathReason = determineDeathReason(DeathCauseHash)
                    TriggerServerEvent('bcc-logs:killlogs', "Killed by NPC", DeathReason .. ' ' .. GetPlayerName(PlayerId()) .. '['..GetPlayerServerId(PlayerId())..']', Weapon)
                end
            elseif IsEntityAVehicle(PedKiller) and IsEntityAPed(GetPedInVehicleSeat(PedKiller, -1)) then
                -- Death caused by a player or NPC in a vehicle
                local vehicleKiller = GetPedInVehicleSeat(PedKiller, -1)
                if IsPedAPlayer(vehicleKiller) then
                    Killer = NetworkGetPlayerIndexFromPed(vehicleKiller)
                    DeathReason = determineDeathReason(DeathCauseHash)
                    TriggerServerEvent('bcc-logs:killlogs', GetPlayerName(Killer) .. '['..GetPlayerServerId(Killer).. '] ' .. DeathReason .. ' ' .. GetPlayerName(PlayerId()) .. '['..GetPlayerServerId(PlayerId())..']', Weapon)
                else
                    DeathReason = determineDeathReason(DeathCauseHash)
                    TriggerServerEvent('bcc-logs:killlogs', "Killed by NPC (Vehicle)", DeathReason .. ' ' .. GetPlayerName(PlayerId()) .. '['..GetPlayerServerId(PlayerId())..']', Weapon)
                end
            else
                -- Self-inflicted or unknown cause
                DeathReason = 'committed suicide' or 'died'
                TriggerServerEvent('bcc-logs:killlogs', GetPlayerName(PlayerId()) .. ' ' .. DeathReason .. '.', Weapon)
            end

            -- Reset variables after logging
            Killer, DeathReason, DeathCauseHash, Weapon = nil, nil, nil, nil
        end

        while IsEntityDead(playerPed) do
            Citizen.Wait(0)
        end
    end
end)

-- Updated helper function to determine death reason based on weapon hash
function determineDeathReason(weaponHash)
    local readableWeaponName = getReadableWeaponName(weaponHash)
    
    if IsMelee(weaponHash) then
        return 'murdered with a ' .. readableWeaponName
    elseif IsPistol(weaponHash) or IsRepeater(weaponHash) or IsRevolver(weaponHash) or IsRifle(weaponHash) then
        return 'shot with a ' .. readableWeaponName
    elseif IsShotgun(weaponHash) then
        return 'blasted with a ' .. readableWeaponName
    elseif IsSniper(weaponHash) then
        return 'sniped with a ' .. readableWeaponName
    elseif IsThrown(weaponHash) then
        return 'exploded by a ' .. readableWeaponName
    elseif IsHeldWeapon(weaponHash) or IsBow(weaponHash) then
        return 'struck with a ' .. readableWeaponName
    elseif IsSpecialWeapon(weaponHash) then
        return 'captured with a ' .. readableWeaponName
    elseif IsUnarmed(weaponHash) then
        return 'attacked by an animal' .. readableWeaponName
    elseif IsEnvironmental(weaponHash) then
        return 'killed by environment'.. readableWeaponName
    else
        return 'killed with a ' .. readableWeaponName
    end
end

-- Define melee weapons
function IsMelee(weaponHash)
    local meleeWeapons = {
        'WEAPON_MELEE_HATCHET_MELEEONLY', 'WEAPON_MELEE_KNIFE_MINER', 'WEAPON_MELEE_KNIFE_JAWBONE',
        'WEAPON_MELEE_KNIFE_VAMPIRE', 'WEAPON_MELEE_KNIFE_JOHN', 'WEAPON_MELEE_MACHETE',
        'WEAPON_MELEE_KNIFE_BEAR', 'WEAPON_MELEE_KNIFE_DUTCH', 'WEAPON_MELEE_KNIFE_KIERAN',
        'WEAPON_MELEE_KNIFE_UNCLE', 'WEAPON_MELEE_KNIFE_SEAN', 'WEAPON_MELEE_TORCH',
        'WEAPON_MELEE_KNIFE_LENNY', 'WEAPON_MELEE_KNIFE_SADIE', 'WEAPON_MELEE_KNIFE_CHARLES',
        'WEAPON_MELEE_KNIFE_HOSEA', 'WEAPON_MELEE_TORCH_CROWD', 'WEAPON_MELEE_KNIFE_BILL',
        'WEAPON_MELEE_KNIFE_CIVIL_WAR', 'WEAPON_MELEE_KNIFE', 'WEAPON_MELEE_KNIFE_MICAH',
        'WEAPON_MELEE_BROKEN_SWORD', 'WEAPON_MELEE_KNIFE_JAVIER', 'WEAPON_MELEE_MACHETE_HORROR',
        'WEAPON_MELEE_KNIFE_TRADER', 'WEAPON_MELEE_MACHETE_COLLECTOR', 'WEAPON_MELEE_KNIFE_HORROR',
        'WEAPON_MELEE_KNIFE_RUSTIC'
    }
    return containsWeapon(weaponHash, meleeWeapons)
end

-- Define pistol weapons
function IsPistol(weaponHash)
    local pistolWeapons = {
        'WEAPON_PISTOL_VOLCANIC', 'WEAPON_PISTOL_MAUSER_DRUNK', 'WEAPON_PISTOL_M1899',
        'WEAPON_PISTOL_SEMIAUTO', 'WEAPON_PISTOL_MAUSER'
    }
    return containsWeapon(weaponHash, pistolWeapons)
end

-- Define repeater weapons
function IsRepeater(weaponHash)
    local repeaterWeapons = {
        'WEAPON_REPEATER_EVANS', 'WEAPON_REPEATER_CARBINE_SADIE', 'WEAPON_REPEATER_HENRY',
        'WEAPON_REPEATER_WINCHESTER', 'WEAPON_REPEATER_WINCHESTER_JOHN', 'WEAPON_REPEATER_CARBINE'
    }
    return containsWeapon(weaponHash, repeaterWeapons)
end

-- Define revolver weapons
function IsRevolver(weaponHash)
    local revolverWeapons = {
        'WEAPON_REVOLVER_DOUBLEACTION', 'WEAPON_REVOLVER_CATTLEMAN', 'WEAPON_REVOLVER_CATTLEMAN_MEXICAN',
        'WEAPON_REVOLVER_LeMAT', 'WEAPON_REVOLVER_SCHOFIELD', 'WEAPON_REVOLVER_DOUBLEACTION_GAMBLER',
        'WEAPON_REVOLVER_NAVY', 'WEAPON_REVOLVER_NAVY_CROSSOVER'
    }
    return containsWeapon(weaponHash, revolverWeapons)
end

-- Define rifle weapons
function IsRifle(weaponHash)
    local rifleWeapons = {
        'WEAPON_RIFLE_SPRINGFIELD', 'WEAPON_RIFLE_BOLTACTION', 'WEAPON_RIFLE_VARMiNT', 'WEAPON_RIFLE_ELEPHANT'
    }
    return containsWeapon(weaponHash, rifleWeapons)
end

-- Define shotgun weapons
function IsShotgun(weaponHash)
    local shotgunWeapons = {
        'WEAPON_SHOTGUN_SAWEDOFF', 'WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC', 'WEAPON_SHOTGUN_PUMP',
        'WEAPON_SHOTGUN_REPEATING', 'WEAPON_SHOTGUN_SEMIAUTO', 'WEAPON_SHOTGUN_DOUBLEBARREL'
    }
    return containsWeapon(weaponHash, shotgunWeapons)
end

-- Define sniper weapons
function IsSniper(weaponHash)
    local sniperWeapons = {
        'WEAPON_SNIPERRIFLE_CARCANO', 'WEAPON_SNIPERRIFLE_ROLLINGBLOCK'
    }
    return containsWeapon(weaponHash, sniperWeapons)
end

-- Define thrown weapons
function IsThrown(weaponHash)
    local thrownWeapons = {
        'WEAPON_THROWN_MOLOTOV', 'WEAPON_THROWN_TOMAHAWK_ANCIENT', 'WEAPON_THROWN_TOMAHAWK',
        'WEAPON_THROWN_DYNAMITE', 'WEAPON_THROWN_THROWING_KNIVES', 'WEAPON_THROWN_BOLAS',
        'WEAPON_THROWN_POISONBOTTLE', 'WEAPON_THROWN_BOLAS_HAWKMOTH', 'WEAPON_THROWN_BOLAS_IRONSPIKED',
        'WEAPON_THROWN_BOLAS_INTERTWINED'
    }
    return containsWeapon(weaponHash, thrownWeapons)
end

-- Define held weapons/tools
function IsHeldWeapon(weaponHash)
    local heldWeapons = {
        'WEAPON_MELEE_LANTERN', 'WEAPON_MELEE_DAVY_LANTERN', 'WEAPON_MELEE_LANTERN_ELECTRIC',
        'WEAPON_KIT_BINOCULARS', 'WEAPON_KIT_CAMERA', 'WEAPON_KIT_CAMERA_ADVANCED', 'WEAPON_KIT_METAL_DETECTOR',
        'WEAPON_MELEE_LANTERN_HALLOWEEN', 'WEAPON_KIT_BINOCULARS_IMPROVED'
    }
    return containsWeapon(weaponHash, heldWeapons)
end

-- Define bow weapons
function IsBow(weaponHash)
    local bowWeapons = {
        'WEAPON_BOW', 'WEAPON_BOW_IMPROVED', 'WEAPON_BOW_CHARLES'
    }
    return containsWeapon(weaponHash, bowWeapons)
end

-- Define special tools/weapons
function IsSpecialWeapon(weaponHash)
    local specialWeapons = {
        'WEAPON_FISHINGROD', 'WEAPON_LASSO', 'WEAPON_LASSO_REINFORCED'
    }
    return containsWeapon(weaponHash, specialWeapons)
end

-- Define unarmed/nature-related weapons
function IsUnarmed(weaponHash)
    local unarmedWeapons = {
        'WEAPON_WOLF', 'WEAPON_WOLF_MEDIUM', 'WEAPON_WOLF_SMALL', 'WEAPON_ALLIGATOR', 'WEAPON_ANIMAL',
        'WEAPON_BADGER', 'WEAPON_BEAR', 'WEAPON_BEAVER', 'WEAPON_COUGAR', 'WEAPON_COYOTE', 'WEAPON_DEER',
        'WEAPON_FOX', 'WEAPON_HORSE', 'WEAPON_MUSKRAT', 'WEAPON_RACCOON', 'WEAPON_SNAKE'
    }
    return containsWeapon(weaponHash, unarmedWeapons)
end

-- Define environmental weapons
function IsEnvironmental(weaponHash)
    local environmentalWeapons = {
        'WEAPON_FALL', 'WEAPON_FIRE', 'WEAPON_BLEEDING', 'WEAPON_DROWNING', 'WEAPON_DROWNING_IN_VEHICLE',
        'WEAPON_EXPLOSION', 'WEAPON_RAMMED_BY_CAR', 'WEAPON_RUN_OVER_BY_CAR'
    }
    return containsWeapon(weaponHash, environmentalWeapons)
end

-- Utility function to check if a weapon hash is in a list of weapons
function containsWeapon(weaponHash, weaponList)
    for _, weapon in ipairs(weaponList) do
        if GetHashKey(weapon) == weaponHash then return true end
    end
    return false
end
-- Helper function to convert weapon hash to readable name
function getReadableWeaponName(weaponHash)
    local weaponName = tostring(weaponHash) -- Convert the hash to a string
    weaponName = weaponName:gsub("WEAPON_", "") -- Remove "WEAPON_" prefix
    weaponName = weaponName:gsub("_", " "):lower() -- Replace underscores with spaces and convert to lowercase
    return weaponName
end

WeaponNames = {
    -- Unarmed
    [tostring(GetHashKey('WEAPON_UNARMED'))] = 'Unarmed',

    -- Melee Weapons
    [tostring(GetHashKey('WEAPON_MELEE_KNIFE'))] = 'Knife',
    [tostring(GetHashKey('WEAPON_MELEE_HATCHET'))] = 'Hatchet',
    [tostring(GetHashKey('WEAPON_MELEE_CLEAVER'))] = 'Cleaver',
    [tostring(GetHashKey('WEAPON_MELEE_MACHETE'))] = 'Machete',
    [tostring(GetHashKey('WEAPON_MELEE_ANCIENT_HATCHET'))] = 'Ancient Hatchet',
    [tostring(GetHashKey('WEAPON_MELEE_CROWBAR'))] = 'Crowbar',
    [tostring(GetHashKey('WEAPON_MELEE_LANTERN'))] = 'Lantern',

    -- Revolvers
    [tostring(GetHashKey('WEAPON_REVOLVER_CATTLEMAN'))] = 'Cattleman Revolver',
    [tostring(GetHashKey('WEAPON_REVOLVER_DOUBLEACTION'))] = 'Double-Action Revolver',
    [tostring(GetHashKey('WEAPON_REVOLVER_LEMAT'))] = 'LeMat Revolver',
    [tostring(GetHashKey('WEAPON_REVOLVER_SCHOFIELD'))] = 'Schofield Revolver',
    [tostring(GetHashKey('WEAPON_REVOLVER_NAVY'))] = 'Navy Revolver',

    -- Pistols
    [tostring(GetHashKey('WEAPON_PISTOL_MAUSER'))] = 'Mauser Pistol',
    [tostring(GetHashKey('WEAPON_PISTOL_SEMIAUTO'))] = 'Semi-Automatic Pistol',
    [tostring(GetHashKey('WEAPON_PISTOL_VOLCANIC'))] = 'Volcanic Pistol',

    -- Rifles
    [tostring(GetHashKey('WEAPON_RIFLE_BOLTACTION'))] = 'Bolt-Action Rifle',
    [tostring(GetHashKey('WEAPON_RIFLE_SPRINGFIELD'))] = 'Springfield Rifle',
    [tostring(GetHashKey('WEAPON_RIFLE_VARMINT'))] = 'Varmint Rifle',
    [tostring(GetHashKey('WEAPON_RIFLE_CARCANO'))] = 'Carcano Rifle',

    -- Repeater Rifles
    [tostring(GetHashKey('WEAPON_REPEATER_CARBINE'))] = 'Carbine Repeater',
    [tostring(GetHashKey('WEAPON_REPEATER_HENRY'))] = 'Henry Repeater',
    [tostring(GetHashKey('WEAPON_REPEATER_WINCHESTER'))] = 'Winchester Repeater',

    -- Shotguns
    [tostring(GetHashKey('WEAPON_SHOTGUN_DOUBLEBARREL'))] = 'Double-Barrel Shotgun',
    [tostring(GetHashKey('WEAPON_SHOTGUN_PUMP'))] = 'Pump-Action Shotgun',
    [tostring(GetHashKey('WEAPON_SHOTGUN_REPEATING'))] = 'Repeating Shotgun',
    [tostring(GetHashKey('WEAPON_SHOTGUN_SAWEDOFF'))] = 'Sawed-Off Shotgun',
    [tostring(GetHashKey('WEAPON_SHOTGUN_SEMIAUTO'))] = 'Semi-Automatic Shotgun',

    -- Sniper Rifles
    [tostring(GetHashKey('WEAPON_SNIPERRIFLE_CARCANO'))] = 'Carcano Sniper Rifle',
    [tostring(GetHashKey('WEAPON_SNIPERRIFLE_ROLLINGBLOCK'))] = 'Rolling Block Rifle',

    -- Bows
    [tostring(GetHashKey('WEAPON_BOW'))] = 'Bow',
    [tostring(GetHashKey('WEAPON_THROWN_TOMAHAWK'))] = 'Tomahawk',

    -- Thrown Weapons
    [tostring(GetHashKey('WEAPON_THROWN_THROWING_KNIVES'))] = 'Throwing Knives',
    [tostring(GetHashKey('WEAPON_THROWN_DYNAMITE'))] = 'Dynamite',
    [tostring(GetHashKey('WEAPON_THROWN_MOLOTOV'))] = 'Molotov',

    -- Miscellaneous
    [tostring(GetHashKey('WEAPON_LASSO'))] = 'Lasso',
    [tostring(GetHashKey('WEAPON_LASSO_REINFORCED'))] = 'Reinforced Lasso',
    [tostring(GetHashKey('WEAPON_MELEE_TORCH'))] = 'Torch'
}

