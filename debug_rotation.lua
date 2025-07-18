-- Comprehensive debugging tool for Fury Warrior rotation
-- This will help identify exactly why abilities aren't being used

function DebugRotationIssues()
    print("=== COMPREHENSIVE ROTATION DEBUG ===")
    
    -- Basic checks
    local targetExists = UnitExists("target")
    local canAttack = UnitCanAttack("player", "target")
    local inCombat = UnitAffectingCombat("player")
    local rage = UnitMana("player") or 0
    
    print("Basic Conditions:")
    print("  Target exists: " .. tostring(targetExists))
    print("  Can attack target: " .. tostring(canAttack))
    print("  In combat: " .. tostring(inCombat))
    print("  Rage: " .. rage)
    
    -- Stance checks
    local _, _, isBattleStance = GetShapeshiftFormInfo(1)
    local _, _, isDefensiveStance = GetShapeshiftFormInfo(2)
    local _, _, isBerserkerStance = GetShapeshiftFormInfo(3)
    
    print("Stance Status:")
    print("  Battle Stance: " .. tostring(isBattleStance))
    print("  Defensive Stance: " .. tostring(isDefensiveStance))
    print("  Berserker Stance: " .. tostring(isBerserkerStance))
    
    -- Check all abilities in detail
    local abilities = {
        {name = "Bloodthirst", stance = "Berserker", rage = 20},
        {name = "Whirlwind", stance = "Berserker", rage = 20},
        {name = "Overpower", stance = "Battle", rage = 5},
        {name = "Execute", stance = nil, rage = 15},
        {name = "Rend", stance = nil, rage = 10},
        {name = "Hamstring", stance = nil, rage = 10},
        {name = "Heroic Strike", stance = nil, rage = 15},
        {name = "Cleave", stance = nil, rage = 20},
        {name = "Charge", stance = "Battle", rage = 0},
        {name = "Battle Shout", stance = nil, rage = 10},
        {name = "Bloodrage", stance = nil, rage = 0},
        {name = "Death Wish", stance = "Berserker", rage = 0},
        {name = "Berserker Rage", stance = "Berserker", rage = 0}
    }
    
    print("Ability Analysis:")
    for _, ability in ipairs(abilities) do
        local cooldown = GetCooldown(ability.name)
        local usable = IsUsable(ability.name)
        local hasRage = rage >= ability.rage
        local correctStance = true
        
        if ability.stance then
            if ability.stance == "Battle" and not isBattleStance then
                correctStance = false
            elseif ability.stance == "Berserker" and not isBerserkerStance then
                correctStance = false
            end
        end
        
        local canUse = usable and hasRage and correctStance and cooldown <= 0
        
        print("  " .. ability.name .. ":")
        print("    Cooldown: " .. string.format("%.1f", cooldown) .. "s")
        print("    Usable: " .. tostring(usable))
        print("    Has rage (" .. ability.rage .. "): " .. tostring(hasRage))
        print("    Correct stance: " .. tostring(correctStance))
        print("    CAN USE: " .. tostring(canUse))
        
        -- Special checks for specific abilities
        if ability.name == "Overpower" then
            local overpowerUsable = OverPowerIsUsable()
            print("    OverPowerIsUsable(): " .. tostring(overpowerUsable))
        elseif ability.name == "Execute" then
            local targetHealth = UnitHealth("target") or 0
            local targetMaxHealth = UnitHealthMax("target") or 1
            local targetHealthPercent = targetHealth / targetMaxHealth
            print("    Target HP%: " .. math.floor(targetHealthPercent * 100) .. "%")
        elseif ability.name == "Rend" then
            local hasRend = GetBuff("target", "Rend")
            local canBleed = CanTargetBleed()
            local isApplied = IsApplied("Rend", 3)
            print("    Has Rend: " .. tostring(hasRend))
            print("    Can bleed: " .. tostring(canBleed))
            print("    Is applied: " .. tostring(isApplied))
        end
    end
    
    -- Check buffs and debuffs
    print("Buffs and Debuffs:")
    local hasRend = GetBuff("target", "Rend")
    local hasBattleShout = GetBuff("player", "Battle Shout")
    local hasEnrage = GetBuff("player", "Enrage")
    local hasHamstring = GetBuff("target", "Hamstring")
    local isPlayer = UnitIsPlayer("target")
    
    print("  Has Rend: " .. tostring(hasRend))
    print("  Has Battle Shout: " .. tostring(hasBattleShout))
    print("  Has Enrage: " .. tostring(hasEnrage))
    print("  Has Hamstring: " .. tostring(hasHamstring))
    print("  Target is player: " .. tostring(isPlayer))
    
    -- Check nearby enemies
    local nearbyEnemies = CountNearbyEnemies()
    print("  Nearby enemies: " .. nearbyEnemies)
    
    -- Action bar mapping check
    print("Action Bar Mapping:")
    for _, ability in ipairs(abilities) do
        local actionSlot = SpellToActionSlot[ability.name]
        if actionSlot then
            print("  " .. ability.name .. " -> slot " .. actionSlot)
        else
            print("  " .. ability.name .. " -> NO SLOT FOUND")
        end
    end
    
    print("=== END DEBUG ===")
end

-- Function to test specific ability usage
function TestAbilityUsage(abilityName)
    print("=== Testing " .. abilityName .. " ===")
    
    local rage = UnitMana("player") or 0
    local cooldown = GetCooldown(abilityName)
    local usable = IsUsable(abilityName)
    local actionSlot = SpellToActionSlot[abilityName]
    
    print("Rage: " .. rage)
    print("Cooldown: " .. string.format("%.1f", cooldown) .. "s")
    print("Usable: " .. tostring(usable))
    print("Action slot: " .. tostring(actionSlot))
    
    if actionSlot then
        local isUsableAction, noMana = IsUsableAction(actionSlot)
        print("IsUsableAction: " .. tostring(isUsableAction))
        print("No mana: " .. tostring(noMana))
    end
    
    -- Try to cast
    print("Attempting to cast...")
    local result = Cast(abilityName)
    print("Cast result: " .. tostring(result))
end

-- Slash command for debugging
SLASH_DEBUGROTATION1 = "/debugrot"
SLASH_DEBUGROTATION2 = "/debugrotation"
SlashCmdList["DEBUGROTATION"] = function(msg)
    if msg == "full" or msg == "" then
        DebugRotationIssues()
    elseif msg == "bloodthirst" then
        TestAbilityUsage("Bloodthirst")
    elseif msg == "whirlwind" then
        TestAbilityUsage("Whirlwind")
    elseif msg == "overpower" then
        TestAbilityUsage("Overpower")
    elseif msg == "execute" then
        TestAbilityUsage("Execute")
    elseif msg == "rend" then
        TestAbilityUsage("Rend")
    elseif msg == "hamstring" then
        TestAbilityUsage("Hamstring")
    elseif msg == "heroic" then
        TestAbilityUsage("Heroic Strike")
    elseif msg == "cleave" then
        TestAbilityUsage("Cleave")
    else
        print("Debug commands:")
        print("/debugrot full - Full rotation analysis")
        print("/debugrot bloodthirst - Test Bloodthirst")
        print("/debugrot whirlwind - Test Whirlwind")
        print("/debugrot overpower - Test Overpower")
        print("/debugrot execute - Test Execute")
        print("/debugrot rend - Test Rend")
        print("/debugrot hamstring - Test Hamstring")
        print("/debugrot heroic - Test Heroic Strike")
        print("/debugrot cleave - Test Cleave")
    end
end

print("Rotation Debug Tool loaded!")
print("Use /debugrot for debugging commands") 