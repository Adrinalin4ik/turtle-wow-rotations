function AssassinationRogueDecision(debugEnabled, minComboPoints)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled
    local minComboPoints = minComboPoints or 4
    local energy = UnitMana("player") or 0

    local health = UnitHealth("player") or 0
    local maxHealth = UnitHealthMax("player") or 1
    local healthPercent = health / maxHealth

    local comboPoints = GetComboPoints("player", "target") or 0

    local nearbyEnemies = CountNearbyEnemies()

    local hasEvasion = GetBuff("player", "Evasion")
    local hasColdBlood = GetBuff("player", "Cold Blood")
    local hasSliceAndDice = GetBuff("player", "Slice and Dice")
    local hasQuelDoreiMeditation = GetBuff("player", "Quel'dorei Meditation")
    local hasEnvenom = GetBuff("player", "Envenom")

    local isPlayer = UnitIsPlayer("target")

    -- When Cold Blood is available, require 5 CP for Eviscerate to maximize the crit
    local coldBloodReady = not OnCooldown("Cold Blood")
    local eviscerateCPThreshold = coldBloodReady and 5 or minComboPoints

    -- Evasion if health is low
    if healthPercent < 0.7 and not hasEvasion then
        if DEBUG then
            print("Health low, using Evasion")
        end
        if Cast("Evasion") then
            return
        end
    end

    -- Quel'dorei Meditation if energy is very low
    if energy <= 20 and not hasQuelDoreiMeditation then
        if DEBUG then
            print("Energy very low, using Quel'dorei Meditation")
        end
        if Cast("Quel'dorei Meditation") then
            return
        end
    end

    -- ATTACKS SECTION

    -- Cold Blood + Eviscerate at 5 combo points for guaranteed crit
    if comboPoints >= 5 and not hasColdBlood and not OnCooldown("Cold Blood") then
        if DEBUG then
            print("5 CP, using Cold Blood before Eviscerate")
        end
        if Cast("Cold Blood") then
            return
        end
    end

    -- Kidney Shot on players at enough combo points
    if comboPoints >= minComboPoints and isPlayer then
        if Cast("Kidney Shot") then
            return
        end
    end

    -- Envenom to boost poison effectiveness (use at 2-3 cp, skip if Cold Blood is ready or Envenom already active)
    if comboPoints == 1 and not hasColdBlood and not hasEnvenom then
        if DEBUG then
            print("Using Envenom at " .. comboPoints .. " CP to boost poisons")
        end
        if Cast("Envenom") then
            return
        end
    end

    -- Eviscerate at enough combo points (Cold Blood buff will make it crit)
    if comboPoints >= eviscerateCPThreshold then
        if DEBUG then
            print("Using Eviscerate at " .. comboPoints .. " CP")
        end
        if Cast("Eviscerate") then
            return
        end
    end

    -- Combo point builder: prefer Noxious Assault, fall back to Hemorrhage
    if IsSpellOnActionBar("Noxious Assault") then
        if Cast("Noxious Assault") then
            return
        end
    elseif IsSpellOnActionBar("Hemorrhage") then
        if Cast("Hemorrhage") then
            return
        end
    end
end
