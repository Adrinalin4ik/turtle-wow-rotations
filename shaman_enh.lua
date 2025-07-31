-- Create tooltip for buff checking
local ShamanTooltip = CreateFrame("GameTooltip", "ShamanTooltip", UIParent, "GameTooltipTemplate")

-- Helper function to determine best shock spell based on target resistance
function GetBestMainShockSpell()
    if not UnitExists("target") then
        return "Frost Shock"  -- Default fallback
    end
    
    local fireResist = GetTargetResistance("Fire")
    local frostResist = GetTargetResistance("Frost")
    local natureResist = GetTargetResistance("Nature")

    -- Find the lowest resistance
    local lowestResist = math.min(natureResist, frostResist)
    
    if CurrentState.debugEnabled then
        print("Resistance check - Fire: " .. fireResist .. ", Frost: " .. frostResist .. ", Nature: " .. natureResist)
        print("Lowest resistance: " .. lowestResist)
    end
    
    -- Return the spell with lowest resistance

    if lowestResist == natureResist then
        return "Earth Shock"
    else
        return "Frost Shock"
    end
end

function ShamanDecision(debugEnabled, shockType, useFlameShock)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled
    hasStormStrike = GetBuff("player", "Stormstrike")
    -- Check if target exists and is attackable
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return
    end
    -- Check for Flame Shock (only if useFlameShock is true and target has low fire resistance)
    if useFlameShock and not GetBuff("target", "Flame Shock") and not IsApplied("Flame Shock", nil) then
        if Cast("Flame Shock", nil) then
            return
        end
    end

    -- Check for Stormstrike
    if Cast("Stormstrike", nil) then
        return
    end

    -- Check for Lightning Strike
    if hasStormStrike and Cast("Lightning Strike", nil) then
        return
    end

    -- Use resistance-based shock selection when Stormstrike is active
    -- if hasStormStrike then
    local bestShock = GetBestMainShockSpell()
    if Cast(bestShock, nil) then
        return
    end
    -- end
end
