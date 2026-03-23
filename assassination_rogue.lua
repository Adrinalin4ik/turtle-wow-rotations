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
    local isEnemyPlayer = UnitExists("target") and UnitIsPlayer("target") and UnitCanAttack("player", "target")

    local targetGUID = (UnitExists("target") and UnitCanAttack("player", "target")) and UnitGUID("target") or nil

    if not UnitAffectingCombat("player") then
        CurrentState.assassinOpenerTargetGUID = nil
        CurrentState.assassinOpenerStep = nil
        CurrentState.assassinOpenerMeditationUsed = false
    elseif isEnemyPlayer and targetGUID then
        if CurrentState.assassinOpenerTargetGUID ~= targetGUID then
            CurrentState.assassinOpenerTargetGUID = targetGUID
            CurrentState.assassinOpenerStep = 1
            CurrentState.assassinOpenerMeditationUsed = false
        end
    else
        CurrentState.assassinOpenerTargetGUID = nil
        CurrentState.assassinOpenerStep = nil
        CurrentState.assassinOpenerMeditationUsed = false
    end

    local openerStep = CurrentState.assassinOpenerStep

    -- When Cold Blood is available, require 5 CP for Eviscerate to maximize the crit (regular rotation)
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

    -- PvP opener: 5 CP + Cold Blood (if off CD) + Eviscerate -> Gouge + Meditation -> Envenom/Kidney -> regular
    if openerStep == 1 then
        if comboPoints < 5 then
            if Cast("Noxious Assault") then
                return
            end
            return
        end
        if not hasColdBlood and not OnCooldown("Cold Blood") then
            if DEBUG then
                print("Opener: 5 CP, Cold Blood")
            end
            if Cast("Cold Blood") then
                return
            end
        elseif OnCooldown("Cold Blood") and not hasColdBlood and DEBUG then
            print("Opener: Cold Blood on CD, skipping to Eviscerate")
        end
        if Cast("Eviscerate") then
            if DEBUG then
                print("Opener: Eviscerate")
            end
            CurrentState.assassinOpenerStep = 2
            return
        end
        return
    end

    if openerStep == 2 then
        if not GetBuff("target", "Gouge") then
            if DEBUG then
                print("Opener: Gouge")
            end
            if Cast("Gouge") then
                return
            end
            return
        end
        if hasQuelDoreiMeditation then
            return
        end
        if not CurrentState.assassinOpenerMeditationUsed then
            if DEBUG then
                print("Opener: Quel'dorei Meditation")
            end
            if Cast("Quel'dorei Meditation") then
                CurrentState.assassinOpenerMeditationUsed = true
                return
            end
            return
        end
        CurrentState.assassinOpenerStep = 3
    end

    -- Use CurrentState here: step may have just advanced from 2 -> 3 in this same call
    if CurrentState.assassinOpenerStep == 3 then
        local openerEnded = false
        if comboPoints >= minComboPoints then
            if OnCooldown("Kidney Shot") then
                if DEBUG then
                    print("Opener: Kidney Shot on CD, ending opener")
                end
                CurrentState.assassinOpenerStep = nil
                CurrentState.assassinOpenerMeditationUsed = false
                openerEnded = true
            else
                if DEBUG then
                    print("Opener: Kidney Shot")
                end
                if Cast("Kidney Shot") then
                    CurrentState.assassinOpenerStep = nil
                    CurrentState.assassinOpenerMeditationUsed = false
                    return
                end
                return
            end
        end
        if not openerEnded then
            if comboPoints >= 1 and not hasEnvenom then
                if DEBUG then
                    print("Opener: Envenom at " .. comboPoints .. " CP")
                end
                if Cast("Envenom") then
                    return
                end
            end
            if Cast("Noxious Assault") then
                return
            end
            return
        end
    end

    -- Quel'dorei Meditation if energy is very low (not during numbered opener; opener handles its own meditate)
    if CurrentState.assassinOpenerStep == nil and energy <= 20 and not hasQuelDoreiMeditation then
        if isEnemyPlayer then
            if GetBuff("target", "Gouge") then
                if DEBUG then
                    print("Energy very low, target Gouged, using Quel'dorei Meditation")
                end
                if Cast("Quel'dorei Meditation") then
                    return
                end
            else
                if DEBUG then
                    print("Energy very low vs player, applying Gouge before Quel'dorei Meditation")
                end
                if Cast("Gouge") then
                    return
                end
            end
        else
            if DEBUG then
                print("Energy very low, using Quel'dorei Meditation")
            end
            if Cast("Quel'dorei Meditation") then
                return
            end
        end
    end

    -- ATTACKS SECTION (regular rotation)

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

    -- Envenom to boost poison effectiveness (use at 1 cp, skip if Cold Blood is ready or Envenom already active)
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

    -- Noxious Assault as combo point builder (applies poisons from both hands)
    if Cast("Noxious Assault") then
        return
    end
end
