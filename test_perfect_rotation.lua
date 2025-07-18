-- Test script for comparing old vs perfect Fury Warrior rotation
-- Usage: Call TestRotation() to switch between rotations

local usePerfectRotation = true
local rotationName = "Perfect"

function TestRotation()
    usePerfectRotation = not usePerfectRotation
    if usePerfectRotation then
        rotationName = "Perfect"
        print("Switched to PERFECT rotation")
    else
        rotationName = "Original"
        print("Switched to ORIGINAL rotation")
    end
end

function GetCurrentRotation()
    if usePerfectRotation then
        return FuryWarriorPerfect
    else
        return FuryWarriorDecision
    end
end

-- Enhanced debug function to show rotation status
function ShowRotationStatus()
    local rage = UnitMana("player") or 0
    local targetHealth = UnitHealth("target") or 0
    local targetMaxHealth = UnitHealthMax("target") or 1
    local targetHealthPercent = targetHealth / targetMaxHealth
    
    print("=== Rotation Status ===")
    print("Current Rotation: " .. rotationName)
    print("Rage: " .. rage)
    print("Target HP%: " .. math.floor(targetHealthPercent * 100))
    print("In Combat: " .. tostring(UnitAffectingCombat("player")))
    print("Target Exists: " .. tostring(UnitExists("target")))
    
    -- Check key abilities
    local abilities = {"Bloodthirst", "Whirlwind", "Overpower", "Execute", "Rend"}
    for _, ability in ipairs(abilities) do
        local cooldown = GetCooldown(ability)
        local usable = IsUsable(ability)
        print(ability .. " - Cooldown: " .. string.format("%.1f", cooldown) .. "s, Usable: " .. tostring(usable))
    end
end

-- Function to run the current rotation with debug enabled
function RunRotation()
    local currentRotation = GetCurrentRotation()
    currentRotation(true) -- Enable debug
end

-- Slash commands for easy testing
SLASH_ROTATION1 = "/rotation"
SLASH_ROTATION2 = "/rot"
SlashCmdList["ROTATION"] = function(msg)
    if msg == "switch" or msg == "toggle" then
        TestRotation()
    elseif msg == "status" then
        ShowRotationStatus()
    elseif msg == "run" then
        RunRotation()
    else
        print("Rotation Commands:")
        print("/rotation switch - Switch between original and perfect rotation")
        print("/rotation status - Show current rotation status")
        print("/rotation run - Run current rotation with debug")
    end
end

print("Perfect Fury Warrior Rotation loaded!")
print("Use /rotation for commands")
print("Current rotation: " .. rotationName) 