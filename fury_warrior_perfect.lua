function FuryWarriorPerfect(debugEnabled, bloodthirstCost)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled
    
    -- Set default Bloodthirst cost if not provided
    bloodthirstCost = bloodthirstCost or 30

    -- Early exit if no target
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        if DEBUG then
            print("No valid target")
        end
        return
    end

    -- Retrieve core stats
    local baseAP, posBuff, negBuff = UnitAttackPower("player")
    baseAP = baseAP or 0
    posBuff = posBuff or 0
    negBuff = negBuff or 0
    local AP = baseAP + posBuff + negBuff
    local rage = UnitMana("player") or 0

    -- Get stance information
    local _, _, isBattleStance = GetShapeshiftFormInfo(1)
    local _, _, isDefensiveStance = GetShapeshiftFormInfo(2)
    local _, _, isBerserkerStance = GetShapeshiftFormInfo(3)

    -- Check buffs and debuffs
    local hasRend = GetBuff("target", "Rend")
    local hasBattleShout = GetBuff("player", "Battle Shout")
    local hasEnrage = GetBuff("player", "Enrage")
    local hasHamstring = GetBuff("target", "Hamstring")
    local isPlayer = UnitIsPlayer("target")
    local nearbyEnemies = CountNearbyEnemies()

    -- Calculate damage for Execute decision
    local targetHealth = UnitHealth("target") or 0
    local targetMaxHealth = UnitHealthMax("target") or 1
    local targetHealthPercent = targetHealth / targetMaxHealth
    local targetArmor = UnitArmor("target") or 0
    local playerLevel = UnitLevel("player") or 60
    local armorReduction = targetArmor / (targetArmor + 400 + 85 * playerLevel)
    armorReduction = math.min(math.max(armorReduction, 0), 0.75)
    
    local Execute_RawDamage = 600 + 15 * math.max(0, rage - 15)
    local Execute_Damage = Execute_RawDamage * (1 - armorReduction)

    -- Get cooldown information for future planning
    local bloodthirstCD = GetCooldown("Bloodthirst")
    local whirlwindCD = GetCooldown("Whirlwind")
    local overpowerUsable = OverPowerIsUsable()

    -- Calculate effective rage after potential stance switch (max 25)
    local effectiveRage = math.min(rage, 25)

    -- Get weapon swing timing information
    local mainHandSpeed = UnitAttackSpeed("player")
    local offHandSpeed = UnitAttackSpeed("player")
    local currentTime = GetTime()
    local timeToNextSwing = 0
    
    -- Calculate time to next swing using math.mod for better precision
    if mainHandSpeed and mainHandSpeed > 0 then
        -- Use math.mod for more reliable floating-point calculations
        local timeSinceLastSwing = math.mod(currentTime, mainHandSpeed)
        timeToNextSwing = mainHandSpeed - timeSinceLastSwing
        
        -- Ensure we don't get negative values
        if timeToNextSwing < 0 then
            timeToNextSwing = 0
        end
    end
    
    -- Estimate rage generation from next swing (typically 5-15 rage per swing)
    local estimatedRageFromSwing = 8 -- Conservative estimate
    local rageAfterSwing = effectiveRage + estimatedRageFromSwing

    if DEBUG then
        print("=== Fury Warrior OPTIMIZED DPS Rotation ===")
        print("Rage: " .. rage .. " (Effective: " .. effectiveRage .. "), AP: " .. AP)
        print("Bloodthirst Cost: " .. bloodthirstCost)
        print("Target HP%: " .. math.floor(targetHealthPercent * 100))
        print("Stance - Battle: " .. tostring(isBattleStance) .. ", Berserker: " .. tostring(isBerserkerStance))
        print("Cooldowns - Bloodthirst: " .. string.format("%.1f", bloodthirstCD) .. "s, Whirlwind: " .. string.format("%.1f", whirlwindCD) .. "s")
        print("Overpower available: " .. tostring(overpowerUsable))
        print("Weapon swing: " .. string.format("%.1f", timeToNextSwing) .. "s, Rage after swing: " .. rageAfterSwing)
        
        -- Check racial abilities
        if IsUsable("Perception") then
            local perceptionCD = GetCooldown("Perception")
            print("Perception - Cooldown: " .. string.format("%.1f", perceptionCD) .. "s, Available: " .. tostring(perceptionCD <= 0))
        else
            print("Perception - Not available (not Human race)")
        end
    end

    -- PRIORITY 1: Overpower (ABSOLUTE HIGHEST PRIORITY - rare, high damage ability)
    if overpowerUsable then
        if DEBUG then print("Priority 1: Using Overpower (highest priority ability)") end
        if Cast("Overpower", "Battle") then return end
    end

    -- PRIORITY 2: Out of combat actions
    if not UnitAffectingCombat("player") then
        if not OnCooldown("Charge") then
            if DEBUG then print("Priority 2: Using Charge") end
            if Cast("Charge", "Battle") then return end
        end
    end

    -- PRIORITY 3: Critical buffs (always maintain)
    if not hasBattleShout and effectiveRage >= 10 then
        if DEBUG then print("Priority 3: Applying Battle Shout") end
        if Cast("Battle Shout") then return end
    end

    -- PRIORITY 4: Execute phase (highest damage priority)
    if targetHealthPercent <= 0.2 and effectiveRage >= 15 then
        if Execute_Damage >= targetHealth or Execute_Damage > 500 then
            if DEBUG then 
                print("Priority 4: Execute phase - Damage: " .. math.floor(Execute_Damage))
            end
            if Cast("Execute") then return end
        end
    end

    -- PRIORITY 5: Combat buffs (only when beneficial)
    if UnitAffectingCombat("player") then
        -- Bloodrage only when rage is low and no better abilities coming soon
        if not hasEnrage and effectiveRage < 20 and bloodthirstCD > 3 and whirlwindCD > 3 and not overpowerUsable then
            if not OnCooldown("Bloodrage") then
                if DEBUG then print("Priority 5: Using Bloodrage (low rage, no abilities soon)") end
                if Cast("Bloodrage") then return end
            end
        end
        
        -- Death Wish for damage increase
        if hasEnrage and not OnCooldown("Death Wish") then
            if DEBUG then print("Priority 5: Using Death Wish") end
            if Cast("Death Wish", "Berserker") then return end
        end
        
        -- Perception racial ability (use with Death Wish for maximum damage)
        if hasEnrage and not OnCooldown("Perception") and IsUsable("Perception") then
            if DEBUG then print("Priority 5: Using Perception racial (with Death Wish)") end
            if Cast("Perception") then return end
        end
    end

    -- PRIORITY 6: Hamstring on players (PvP) - only when safe
    if isPlayer and not hasHamstring and effectiveRage >= 10 and effectiveRage < 20 then
        if DEBUG then print("Priority 6: Applying Hamstring to player") end
        if Cast("Hamstring") then return end
    end

    -- PRIORITY 7: Rend application (only when beneficial)
    if not hasRend and effectiveRage >= 10 and CanTargetBleed() and not IsApplied("Rend", 3) then
        -- Only apply Rend if we have enough effective rage for upcoming abilities
        if effectiveRage >= 20 or (bloodthirstCD > 2 and whirlwindCD > 2) then
            if DEBUG then print("Priority 7: Applying Rend") end
            if Cast("Rend") then return end
        end
    end

    -- PRIORITY 8: Berserker Rage for rage generation (only when needed)
    if effectiveRage < 20 and not OnCooldown("Berserker Rage") and isBerserkerStance then
        -- Only use if we need rage for upcoming abilities
        if bloodthirstCD < 2 or (whirlwindCD < 2 and bloodthirstCD > 3) then
            if DEBUG then print("Priority 8: Using Berserker Rage (abilities coming soon)") end
            if Cast("Berserker Rage", "Berserker") then return end
        end
    end

    -- PRIORITY 9: Main damage rotation (Berserker Stance)
    if isBerserkerStance and effectiveRage >= bloodthirstCost then
        -- Bloodthirst (highest priority damage ability)
        if bloodthirstCD <= 0 then
            if DEBUG then print("Priority 9: Using Bloodthirst (Cost: " .. bloodthirstCost .. ")") end
            if Cast("Bloodthirst", "Berserker") then return end
        end
        
        -- Whirlwind (use when available if we have enough rage for both abilities)
        if whirlwindCD <= 0 then
            -- Use Whirlwind if we have enough rage for both Bloodthirst and Whirlwind
            -- or if Bloodthirst is on cooldown and we have enough rage
            if (effectiveRage >= (bloodthirstCost + 25) and bloodthirstCD <= 0) or 
               (effectiveRage >= 25 and bloodthirstCD > 0) then
                if DEBUG then print("Priority 9: Using Whirlwind (sufficient rage for both abilities)") end
                if Cast("Whirlwind", "Berserker") then return end
            end
        end
    end

    -- PRIORITY 10: Stance optimization for Overpower and Bloodthirst
    if effectiveRage >= bloodthirstCost then
        -- Switch to Battle Stance ONLY if Overpower is available or coming very soon
        if not isBattleStance and overpowerUsable then
            if DEBUG then print("Priority 10: Switching to Battle Stance (Overpower available)") end
            if Cast("Battle Stance") then return end
        end
        
        -- Switch to Berserker Stance if we're in Battle Stance but Overpower is not available
        if isBattleStance and not overpowerUsable and (bloodthirstCD < 1 or whirlwindCD < 1) then
            if DEBUG then print("Priority 10: Switching to Berserker Stance (abilities available, no Overpower)") end
            if Cast("Berserker Stance") then return end
        end
        
        -- Switch to Berserker Stance if Bloodthirst is coming off cooldown soon and no Overpower available
        if not isBerserkerStance and bloodthirstCD < 1 and not overpowerUsable then
            if DEBUG then print("Priority 10: Switching to Berserker Stance (Bloodthirst coming off CD)") end
            if Cast("Berserker Stance") then return end
        end
    end

    -- PRIORITY 10.5: Aggressive stance switching to prevent rage loss
    if rage > 25 then
        -- If we have excess rage and no Overpower available, switch to Berserker Stance immediately
        if not isBerserkerStance and not overpowerUsable then
            if DEBUG then print("Priority 10.5: Switching to Berserker Stance (preventing rage loss)") end
            if Cast("Berserker Stance") then return end
        end
    end

    -- PRIORITY 11: Smart rage dump (considering stance switching penalty and Overpower priority)
    if rage > 60 then
        -- High rage dump - use Cleave for multiple enemies
        if nearbyEnemies > 1 then
            if DEBUG then print("Priority 11: Using Cleave (high rage dump)") end
            if Cast("Cleave") then return end
        else
            if DEBUG then print("Priority 11: Using Heroic Strike (high rage dump)") end
            if Cast("Heroic Strike") then return end
        end
    elseif rage > 40 then
        -- Medium rage dump - only if no important abilities coming soon
        if bloodthirstCD > 2 and whirlwindCD > 2 and not overpowerUsable then
            if nearbyEnemies > 1 then
                if DEBUG then print("Priority 11: Using Cleave (medium rage dump)") end
                if Cast("Cleave") then return end
            else
                if DEBUG then print("Priority 11: Using Heroic Strike (medium rage dump)") end
                if Cast("Heroic Strike") then return end
            end
        end
    elseif rage > 30 then
        -- Low rage dump - be more aggressive when no better options
        if bloodthirstCD > 3 and whirlwindCD > 3 and not overpowerUsable then
            if nearbyEnemies > 1 then
                if DEBUG then print("Priority 11: Using Cleave (low rage dump)") end
                if Cast("Cleave") then return end
            else
                if DEBUG then print("Priority 11: Using Heroic Strike (low rage dump)") end
                if Cast("Heroic Strike") then return end
            end
        end
    end

    -- PRIORITY 12: Battle Stance damage rotation (when Berserker abilities are on cooldown)
    if isBattleStance and effectiveRage >= 20 then
        -- Only use Heroic Strike if we have excess rage and no better options
        if rage > 25 and bloodthirstCD > 2 and whirlwindCD > 2 then
            if DEBUG then print("Priority 12: Using Heroic Strike in Battle Stance") end
            if Cast("Heroic Strike", "Battle") then return end
        end
    end

    -- PRIORITY 13: Default to Berserker Stance (maximize damage bonuses)
    if not isBerserkerStance and not overpowerUsable and effectiveRage >= 15 then
        if DEBUG then print("Priority 13: Switching to Berserker Stance (default stance for damage)") end
        if Cast("Berserker Stance") then return end
    end

    -- PRIORITY 14: Emergency rage dump (only when absolutely necessary)
    if rage > 70 then
        if DEBUG then print("Priority 14: Emergency rage dump") end
        if Cast("Heroic Strike") then return end
    end

    if DEBUG then
        print("=== Rotation Complete ===")
        print("Rage: " .. rage .. " (Effective: " .. effectiveRage .. ") - No actions taken (saving for better abilities)")
        print("Upcoming abilities:")
        print("  Overpower available: " .. tostring(overpowerUsable))
        print("  Bloodthirst: " .. string.format("%.1f", bloodthirstCD) .. "s")
        print("  Whirlwind: " .. string.format("%.1f", whirlwindCD) .. "s")
        print("  Stance switching would save: " .. math.min(rage, 25) .. " rage")
        print("  Next weapon swing in: " .. string.format("%.1f", timeToNextSwing) .. "s")
    end
end

-- Enhanced Cast function specifically for the perfect rotation
function PerfectCast(spellName, requiredStance)
    local DEBUG = CurrentState.debugEnabled
    
    -- Get current stance
    local _, _, isBattleStance = GetShapeshiftFormInfo(1)
    local _, _, isDefensiveStance = GetShapeshiftFormInfo(2)
    local _, _, isBerserkerStance = GetShapeshiftFormInfo(3)
    
    -- Check if spell is on cooldown
    if OnCooldown(spellName) then
        if DEBUG then
            print("PerfectCast: " .. spellName .. " is on cooldown")
        end
        return false
    end

    -- Handle stance requirements
    if requiredStance == "Battle" and not isBattleStance then
        if DEBUG then
            print("PerfectCast: Switching to Battle Stance for " .. spellName)
        end
        CastSpellByName("Battle Stance")
        return false
    elseif requiredStance == "Berserker" and not isBerserkerStance then
        if DEBUG then
            print("PerfectCast: Switching to Berserker Stance for " .. spellName)
        end
        CastSpellByName("Berserker Stance")
        return false
    end

    -- Check if spell is usable
    if not IsUsable(spellName) then
        if DEBUG then
            print("PerfectCast: " .. spellName .. " is not usable")
        end
        return false
    end

    -- Cast the spell
    if DEBUG then
        print("PerfectCast: Successfully casting " .. spellName)
    end
    CastSpellByName(spellName)
    
    -- Record the cast time
    CurrentState.skillCastTimes[spellName] = GetTime()
    
    return true
end

-- Override the Cast function to use PerfectCast
local originalCast = Cast
Cast = PerfectCast 