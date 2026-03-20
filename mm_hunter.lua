-- Marksmanship Hunter rotation
-- Uses UpdateAutoShotState / TrackAutoAttack from bm_hunter.lua when present; otherwise defines them below.

function MMHunterDecision(debugEnabled)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled

    local mana = UnitMana("player") or 0
    local maxMana = UnitManaMax("player") or 1
    local manaPercent = mana / maxMana

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

    -- Priority 1: Concussive Shot if target is missing the slow/debuff
    local hasConcussive = GetBuff("target", "Concussive Shot")
    if not hasConcussive and not OnCooldown("Concussive Shot") and IsUsable("Concussive Shot") then
        if DEBUG then
            print("Applying Concussive Shot")
        end
        if Cast("Concussive Shot") then
            return
        end
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

    -- Priority 5: Serpent Sting if not on target
    if not GetBuff("target", "Serpent Sting") and not OnCooldown("Serpent Sting") and IsUsable("Serpent Sting") then
        if DEBUG then
            print("Applying Serpent Sting")
        end
        if Cast("Serpent Sting") then
            return
        end
    end

    -- Priority 6: Steady Shot (lowest priority filler)
    if not OnCooldown("Steady Shot") and IsUsable("Steady Shot") then
        if DEBUG then
            print("Casting Steady Shot (filler)")
        end
        if Cast("Steady Shot") then
            return
        end
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
