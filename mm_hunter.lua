-- Marksmanship Hunter rotation
-- Uses UpdateAutoShotState / TrackAutoAttack from bm_hunter.lua when present; otherwise defines them below.

-- manageHuntersMark: when true, applies Hunter's Mark if missing — first priority if target HP > 70%, lowest if <= 70%
function MMHunterDecision(debugEnabled, manageHuntersMark)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled
    manageHuntersMark = manageHuntersMark and true or false

    local mana = UnitMana("player") or 0
    local maxMana = UnitManaMax("player") or 1
    local manaPercent = mana / maxMana

    local function tryTrueshotAura()
        if UnitAffectingCombat("player") then
            return false
        end
        if GetBuff("player", "Trueshot Aura") then
            return false
        end
        if OnCooldown("Trueshot Aura") or not IsUsable("Trueshot Aura") then
            return false
        end
        if DEBUG then
            print("Applying Trueshot Aura (out of combat)")
        end
        return Cast("Trueshot Aura")
    end

    local function tryAspectOfTheViper()
        if manaPercent >= 0.4 then
            return false
        end
        if GetBuff("player", "Aspect of the Viper") then
            return false
        end
        if OnCooldown("Aspect of the Viper") or not IsUsable("Aspect of the Viper") then
            return false
        end
        if DEBUG then
            print("Switching to Aspect of the Viper (mana " .. string.format("%.0f", manaPercent * 100) .. "%)")
        end
        return Cast("Aspect of the Viper")
    end

    local function tryAspectOfTheHawk()
        if manaPercent <= 0.95 then
            return false
        end
        if GetBuff("player", "Aspect of the Hawk") then
            return false
        end
        if OnCooldown("Aspect of the Hawk") or not IsUsable("Aspect of the Hawk") then
            return false
        end
        if DEBUG then
            print("Switching to Aspect of the Hawk (mana " .. string.format("%.0f", manaPercent * 100) .. "%)")
        end
        return Cast("Aspect of the Hawk")
    end

    if tryTrueshotAura() then
        return
    end
    if tryAspectOfTheViper() then
        return
    end
    if tryAspectOfTheHawk() then
        return
    end

    if not UnitExists("target") then
        if DEBUG then
            print("No target selected")
        end
        return
    end

    if not UnitCanAttack("player", "target") then
        if DEBUG then
            print("Target is not attackable")
        end
        return
    end

    UpdateAutoShotState()

    local isMidShot, timeRemaining = GetSecondsRemainingShoot()
    local isReloading, reloadTimeRemaining = GetSecondsRemainingReload()

    if DEBUG then
        print("Mana: " .. mana .. "/" .. maxMana .. " (" .. string.format("%.1f", manaPercent * 100) .. "%)")
        if isMidShot then
            print("Mid-shot, time remaining: " .. string.format("%.2f", timeRemaining) .. "s")
        elseif isReloading then
            print("Reloading, time remaining: " .. string.format("%.2f", reloadTimeRemaining) .. "s")
        else
            print("Ready to cast spells")
        end
    end

    if isMidShot then
        if DEBUG then
            print("Mid-shot, waiting... (time remaining: " .. string.format("%.2f", timeRemaining) .. "s)")
        end
        return
    end

    local hpMax = UnitHealthMax("target") or 1
    local hp = UnitHealth("target") or 0
    local hpPct = hpMax > 0 and (hp / hpMax) or 0

    local function tryHuntersMarkHighPriority()
        if not manageHuntersMark or hpPct <= 0.7 then
            return false
        end
        if GetBuff("target", "Hunter's Mark") then
            return false
        end
        if OnCooldown("Hunter's Mark") or not IsUsable("Hunter's Mark") then
            return false
        end
        if DEBUG then
            print("Applying Hunter's Mark (high priority, target " .. string.format("%.0f", hpPct * 100) .. "% HP)")
        end
        return Cast("Hunter's Mark")
    end

    local function tryHuntersMarkLowPriority()
        if not manageHuntersMark or hpPct > 0.7 then
            return false
        end
        if GetBuff("target", "Hunter's Mark") then
            return false
        end
        if OnCooldown("Hunter's Mark") or not IsUsable("Hunter's Mark") then
            return false
        end
        if DEBUG then
            print("Applying Hunter's Mark (low priority, target " .. string.format("%.0f", hpPct * 100) .. "% HP)")
        end
        return Cast("Hunter's Mark")
    end

    if tryHuntersMarkHighPriority() then
        return
    end

    -- Priority 1: Concussive Shot if debuff missing — not on bosses, elite, or skull-level mobs
    if not IsTargetRarity("target") then
        local hasConcussive = GetBuff("target", "Concussive Shot")
        if not hasConcussive and not OnCooldown("Concussive Shot") and IsUsable("Concussive Shot") then
            if DEBUG then
                print("Applying Concussive Shot")
            end
            if Cast("Concussive Shot") then
                return
            end
        end
    elseif DEBUG then
        print("Skipping Concussive Shot (boss or elite target)")
    end

    -- Priority 2: Arcane Shot
    if not OnCooldown("Arcane Shot") and IsUsable("Arcane Shot") then
        if DEBUG then
            print("Casting Arcane Shot")
        end
        if Cast("Arcane Shot") then
            return
        end
    end

    -- Priority 3: Aimed Shot when Lock and Load is active (instant proc)
    local hasLockAndLoad = GetBuff("player", "Lock and Load")
    if hasLockAndLoad and not OnCooldown("Aimed Shot") and IsUsable("Aimed Shot") then
        if DEBUG then
            print("Casting Aimed Shot (Lock and Load)")
        end
        if Cast("Aimed Shot") then
            return
        end
    end

    -- Priority 4: Aimed Shot
    if not OnCooldown("Aimed Shot") and IsUsable("Aimed Shot") then
        if DEBUG then
            print("Casting Aimed Shot")
        end
        if Cast("Aimed Shot") then
            return
        end
    end

    -- Priority 5: Steady Shot (lowest priority filler)
    if not OnCooldown("Steady Shot") and IsUsable("Steady Shot") then
        if DEBUG then
            print("Casting Steady Shot (filler)")
        end
        if Cast("Steady Shot") then
            return
        end
    end

    if tryHuntersMarkLowPriority() then
        return
    end

    if DEBUG then
        print("No actions to perform, waiting for next auto attack")
    end
end

if not TrackAutoAttack then
    function TrackAutoAttack()
        local currentTime = GetTime()
        CurrentState.lastAutoAttack = currentTime
        if CurrentState.debugEnabled then
            print("Auto attack detected at: " .. string.format("%.2f", currentTime))
        end
    end
end

if not UpdateAutoShotState then
    function UpdateAutoShotState()
        if not CurrentState.isShooting and not CurrentState.isReloading then
            return
        end
        local currentTime = GetTime()
        if CurrentState.isShooting then
            local shootElapsed = currentTime - CurrentState.shootStartTime
            if shootElapsed >= _AIMING_TIME then
                CurrentState.isShooting = false
                CurrentState.isReloading = true
                CurrentState.reloadStartTime = currentTime
                if CurrentState.debugEnabled then
                    print("Shooting phase complete, starting reload")
                end
            end
        end
        if CurrentState.isReloading then
            local reloadElapsed = currentTime - CurrentState.reloadStartTime
            local reloadTime = CurrentState.rangedSpeed - _AIMING_TIME
            if reloadElapsed >= reloadTime then
                CurrentState.isReloading = false
                CurrentState.isShooting = true
                CurrentState.shootStartTime = currentTime
                if CurrentState.debugEnabled then
                    print("Reload complete, starting next shot")
                end
            end
        end
    end
end
