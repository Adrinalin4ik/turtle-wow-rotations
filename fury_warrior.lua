
function FuryWarriorDecision(debugEnabled)
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
    local BT_RawDamage = 200 + 0.35 * AP
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
    local BT_Damage = BT_RawDamage * (1 - armorReduction)
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

    -- Check for Hamstring on enemy playersw
    if isPlayer and not hasHamstring and rage >= 10 then
        if DEBUG then
            print("Enemy player without Hamstring, applying Hamstring")
        end
        if Cast("Hamstring") then
            return
        end
    end


    -- Battle Stance Logic
    if (rage <= 30 and isBerserkerStance) or isBattleStance then
        -- Check for dodge first (highest priority)
        if OverPowerIsUsable() then
            if Cast("Overpower", "Battle") then
                return
            end
        -- Check for Rend if no dodge (only on creatures that can bleed)
        elseif not hasRend and rage >= 10 and not IsApplied("Rend", nil) and CanTargetBleed() and isBattleStance then
            if DEBUG then
                print("No Rend on target, applying Rend")
            end
            if Cast("Rend", "Battle") then
                return
            end
        elseif rage > 25 and isBattleStance then
            if not OnCooldown("Bloodthirst") then
                Cast("Bloodthirst", nil)
            else
                Cast("Heroic Strike", nil)
            end
        else
            -- If no conditions met, switch back to Berserker
            if DEBUG then
                print("No Battle Stance conditions met, switching back to Berserker")
            end
            if IsApplied("Rend", nil) or not CanTargetBleed() then
                Cast("Berserker Stance", nil)
            end
        end
    elseif not isBerserkerStance and not OverPowerIsUsable() and rage < 25 then
        if DEBUG then
            print("No Battle Stance conditions met, switching back to Berserker")
        end
        Cast("Berserker Stance", nil)
    end

    
    if rage < 30 and not OnCooldown("Berserker Rage") and isBerserkerStance then
        if Cast("Berserker Rage", "Berserker") then
            return
        end
    end


    -- if OverPowerIsUsable() and rage <= 35 then
    --     return;
    -- end

    -- General buffs
    if not hasBattleShout and rage >= 10 then
        if DEBUG then
            print("No Battle Shout, applying Battle Shout")
        end
        if Cast("Battle Shout") then
            return
        end
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

    
    -- Check for Death Wish (only in combat, after Bloodrage)
    if UnitAffectingCombat("player") and not OnCooldown("Death Wish") and hasEnrage then
        if DEBUG then
            print("Using Death Wish for increased damage")
        end
        if Cast("Death Wish", "Berserker") then
            return
        end
    end

    -- Logging for debugging purposes (round only printed numbers)
    if DEBUG then
        local rounded_BT = math.floor(BT_Damage + 0.5)
        local rounded_Execute = math.floor(Execute_Damage + 0.5)

        print("AP: " .. AP .. ", Rage: " .. rage)
        print("Raw BT: " .. math.floor(BT_RawDamage + 0.5) .. ", Adjusted BT: " .. rounded_BT)
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
        if Execute_Damage >= targetHealth or Execute_Damage > BT_Damage then
            if DEBUG then
                print("Execute can kill! Casting Execute (" .. math.floor(Execute_Damage + 0.5) .. " dmg)")
            end
            Cast("Execute", nil)
        end
    end
    if rage >= 20 and isBerserkerStance then
        if not OnCooldown("Bloodthirst") then
            Cast("Bloodthirst", "Berserker")
        elseif not OnCooldown("Whirlwind") and not OverPowerIsUsable() then
            if DEBUG then
                print("Using Whirlwind as filler")
            end
            Cast("Whirlwind", "Berserker")
        elseif (rage > 35 and GetCooldown('Whirlwind') > 4 and GetCooldown('Bloodthirst') > 2) or rage > 45 then
            if nearbyEnemies > 1 then
                if DEBUG then
                    print("Multiple enemies detected, using Cleave as rage dump")
                end
                Cast("Cleave", "Berserker")
            else
                if DEBUG then
                    print("Using Heroic Strike as rage dump")
                end
                Cast("Heroic Strike", "Berserker")
            end
        end
    end
end