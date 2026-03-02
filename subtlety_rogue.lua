function SubtletyRogueDecision(debugEnabled, minComboPoints)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled
    local minComboPoints = minComboPoints or 3
    -- Retrieve current Energy
    local energy = UnitMana("player") or 0

    -- Retrieve current Health and Max Health
    local health = UnitHealth("player") or 0
    local maxHealth = UnitHealthMax("player") or 1
    local healthPercent = health / maxHealth

    -- Get combo points
    local comboPoints = GetComboPoints("player", "target") or 0

    -- Check nearby enemies
    local nearbyEnemies = CountNearbyEnemies()

    -- Check current buffs
    local hasEvasion = GetBuff("player", "Evasion")
    local hasSliceAndDice = GetBuff("player", "Slice and Dice")
    local hasQuelDoreiMeditation = GetBuff("player", "Quel'dorei Meditation")

    -- Check if target is player
    local isPlayer = UnitIsPlayer("target")

    -- 2. Evasion if health is low
    if healthPercent < 0.7 and not hasEvasion then
        if DEBUG then
            print("Health low, using Evasion")
        end
        if Cast("Evasion") then
            return
        end
    end

    -- 3. Quel'dorei Meditation if energy is very low
    if energy <= 20 and not hasQuelDoreiMeditation then
        if DEBUG then
            print("Energy very low, using Quel'dorei Meditation")
        end
        if Cast("Quel'dorei Meditation") then
            return
        end
    end

    -- ATTACKS SECTION
    -- 1. Riposte after parrying (high priority)
    if Cast("Riposte") then
        return
    end


    -- 2. Surprise Attack after dodge
    if Cast("Surprise Attack") then
        return
    end

    -- 3. Slice and Dice with 2 combo points
    -- if comboPoints >= 1 and not hasSliceAndDice then
    --     if Cast("Slice and Dice") then
    --         return
    --     end
    -- end

    -- 4. Kidney Shot with 4-5 combo points (only on players)
    if comboPoints >= minComboPoints and isPlayer then
        if Cast("Kidney Shot") then
            return
        end
    end

    -- 5. Eviscerate with 4-5 combo points
    if comboPoints >= minComboPoints then
        if Cast("Eviscerate") then
            return
        end
    end

    -- 6. Ghostly Strike if available
    if Cast("Ghostly Strike") then
        return
    end

    -- 7. Sinister Strike if available
    -- Then cast Sinister Strike
    if Cast("Sinister Strike") then
        return
    end
end 