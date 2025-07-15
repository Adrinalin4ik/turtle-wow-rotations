local function OverPowerIsUsable()
    local rage = UnitMana("player") or 0
    if GetTime() - CurrentState.lastDodge < 5 and rage >= 5 and not OnCooldown("Overpower") then
        return true
    end
    return false
end

function ArmsWarriorDecision(debugEnabled)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled

    -- Retrieve Attack Power components
    local baseAP, posBuff, negBuff = UnitAttackPower("player")
    baseAP = baseAP or 0
    posBuff = posBuff or 0
    negBuff = negBuff or 0
    local AP = baseAP + posBuff + negBuff

    -- Retrieve current Rage
    local rage = UnitMana("player") or 0

    -- Calculate potential raw damages
    -- Get main hand (right hand) weapon damage for Mortal Strike calculation (120% weapon damage)
    local mainHandMin, mainHandMax = UnitDamage("player")
    local weaponDamage = (mainHandMin + mainHandMax) / 2  -- Average main hand weapon damage
    local MS_RawDamage = weaponDamage * 1.2-- Mortal Strike: 120% weapon damage
    local Execute_RawDamage = 600 + 15 * math.max(0, rage - 15)

    -- Retrieve target's health and health percentage
    local targetHealth = UnitHealth("target") or 0
    local targetMaxHealth = UnitHealthMax("target") or 1  -- Prevent division by zero
    local targetHealthPercent = targetHealth / targetMaxHealth

    -- Estimate target's armor
    local targetArmor = UnitArmor("target") or 0
    local playerLevel = UnitLevel("player") or 60  -- Assume 60 if can't retrieve
    local armorReduction = targetArmor / (targetArmor + 400 + 85 * playerLevel)
    armorReduction = math.min(math.max(armorReduction, 0), 0.75)  -- Clamp between 0% and 75%

    -- Calculate actual expected damage after armor reduction
    local MS_Damage = MS_RawDamage * (1 - armorReduction)
    local Execute_Damage = Execute_RawDamage * (1 - armorReduction)

    -- Get current stance
    local _, _, isBattleStance = GetShapeshiftFormInfo(1)
    local _, _, isDefensiveStance = GetShapeshiftFormInfo(2)
    local _, _, isBerserkerStance = GetShapeshiftFormInfo(3)

    -- Check if we have Rend on target
    local hasRend = GetBuff("target", "Rend")
    -- Check if we have Battle Shout
    local hasBattleShout = GetBuff("player", "Battle Shout")
    -- Check if we have Enrage
    local hasEnrage = GetBuff("player", "Enrage")
    -- Check if target has Hamstring
    local hasHamstring = GetBuff("target", "Hamstring")
    -- Check if target is player
    local isPlayer = UnitIsPlayer("target")
    -- Check nearby enemies
    local nearbyEnemies = CountNearbyEnemies()

    -- Use Charge when out of combat
    if not UnitAffectingCombat("player") and not OnCooldown("Charge") then
        if DEBUG then
            print("Out of combat, using Charge")
        end
        if Cast("Charge", "Battle") then
            return
        end
    end

    -- Battle Stance Logic
    if rage <= 30 or isBattleStance then
        -- Check for dodge first (highest priority)
        if OverPowerIsUsable() then
            if Cast("Overpower", "Battle") then
                return
            end
        -- Check for Rend if no dodge (only on creatures that can bleed)
        elseif not hasRend and rage >= 10 and not IsApplied("Rend", nil) and CanTargetBleed() then
            if DEBUG then
                print("No Rend on target, applying Rend")
            end
            if Cast("Rend", "Battle") then
                return
            end
        else
            -- If no conditions met, switch back to Berserker
            if DEBUG then
                print("No Battle Stance conditions met, switching back to Berserker")
            end
            Cast("Berserker Stance", nil)
        end
    elseif not isBerserkerStance and not OverPowerIsUsable() then
        if DEBUG then
            print("No Battle Stance conditions met, switching back to Berserker")
        end
        Cast("Berserker Stance", nil)
    end

    -- Check for Bloodrage (only in combat)
    if UnitAffectingCombat("player") and not hasEnrage and rage < 60 and not OnCooldown("Bloodrage") then
        if DEBUG then
            print("Low rage and no Enrage, using Bloodrage")
        end
        if Cast("Bloodrage", nil) then
            return
        end
    end

    if rage < 30 and not OnCooldown("Berserker Rage") and isBerserkerStance then
        if Cast("Berserker Rage", "Berserker") then
            return
        end
    end


    if OverPowerIsUsable() and rage <= 30 then
        return;
    end

    -- General buffs
    if not hasBattleShout and rage >= 10 then
        if DEBUG then
            print("No Battle Shout, applying Battle Shout")
        end
        if Cast("Battle Shout") then
            return
        end
    end

    -- Check for Hamstring on enemy players
    if isPlayer and not hasHamstring and rage >= 10 then
        if DEBUG then
            print("Enemy player without Hamstring, applying Hamstring")
        end
        if Cast("Hamstring", "Berserker") then
            return
        end
    end
    
    -- Logging for debugging purposes (round only printed numbers)
    if DEBUG then
        local rounded_MS = math.floor(MS_Damage + 0.5)
        local rounded_Execute = math.floor(Execute_Damage + 0.5)

        print("AP: " .. AP .. ", Rage: " .. rage)
        print("Raw MS: " .. math.floor(MS_RawDamage + 0.5) .. ", Adjusted MS: " .. rounded_MS)
        print("Raw Execute: " .. math.floor(Execute_RawDamage + 0.5) .. ", Adjusted Execute: " .. rounded_Execute)
        print("Target Health %: " .. math.floor(targetHealthPercent * 100))
        print("Armor Reduction: " .. (math.floor(armorReduction * 10000) / 100) .. "%")
        print("Battle Stance: " .. tostring(isBattleStance))
        print("Berserker Stance: " .. tostring(isBerserkerStance))
        print("Has Rend: " .. tostring(hasRend))
        print("Has Battle Shout: " .. tostring(hasBattleShout))
        print("Has Enrage: " .. tostring(hasEnrage))
        print("Target Creature Type: " .. GetTargetCreatureType())
        print("Can Target Bleed: " .. tostring(CanTargetBleed()))
    end

    -- Decision-making logic
    if targetHealthPercent <= 0.2 and rage >= 15 then
        if Execute_Damage >= targetHealth or Execute_Damage > MS_Damage then
            if DEBUG then
                print("Execute can kill! Casting Execute (" .. math.floor(Execute_Damage + 0.5) .. " dmg)")
            end
            Cast("Execute", nil)
        end
    end
    if rage >= 20 and isBerserkerStance then
        if not OnCooldown("Mortal Strike") then
            Cast("Mortal Strike", "Berserker")
        elseif not OnCooldown("Whirlwind") then
            Cast("Whirlwind", "Berserker")
        elseif rage > 20 then
            Cast("Heroic Strike", "Berserker")
            -- Cast("Slam", "Berserker")
            -- if nearbyEnemies > 1 then
            --     Cast("Cleave", "Berserker")
            -- else
            --     if DEBUG then
            --         print("Using Slam as rage dump")
            --     end
            --     Cast("Slam", "Berserker")
            --     -- if DEBUG then
            --     --     print("Using Heroic Strike as rage dump")
            --     -- end
            --     -- Cast("Heroic Strike", "Berserker")
            -- end
        end
    end
end