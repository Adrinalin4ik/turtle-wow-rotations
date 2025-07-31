function BMHunterDecision(debugEnabled)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled

    -- Get current mana
    local mana = UnitMana("player") or 0
    local maxMana = UnitManaMax("player") or 1
    local manaPercent = mana / maxMana

    -- Check if we have a target
    if not UnitExists("target") then
        if DEBUG then
            print("No target selected")
        end
        return
    end

    -- Check if target is attackable
    if not UnitCanAttack("player", "target") then
        if DEBUG then
            print("Target is not attackable")
        end
        return
    end

    -- Update auto shot state
    UpdateAutoShotState()
    
    -- Use Quiver-style timing logic
    local isMidShot, timeRemaining, midShotElapsedTime = GetSecondsRemainingShoot()
    local isReloading, reloadTimeRemaining, reloadElapsedTime = GetSecondsRemainingReload()
    -- print("reloadElapsedTime: " .. reloadElapsedTime .. " reloadTimeRemaining: " .. reloadTimeRemaining)
    -- print("midShotElapsedTime: " .. midShotElapsedTime .. " timeRemaining: " .. timeRemaining)
    if DEBUG then
        print("Mana: " .. mana .. "/" .. maxMana .. " (" .. string.format("%.1f", manaPercent * 100) .. "%)")
        local isMidShot, timeRemaining = GetSecondsRemainingShoot()
        local isReloading, reloadTimeRemaining = GetSecondsRemainingReload()
        if isMidShot then
            print("Mid-shot, time remaining: " .. string.format("%.2f", timeRemaining) .. "s")
        elseif isReloading then
            print("Reloading, time remaining: " .. string.format("%.2f", reloadTimeRemaining) .. "s")
        else
            print("Ready to cast spells")
        end
    end

    -- Don't cast if we're in the middle of a shot (aiming phase)
    if isMidShot then
        if DEBUG then
            print("Mid-shot, waiting... (time remaining: " .. string.format("%.2f", timeRemaining) .. "s)")
        end
        return
    end

    -- Priority 1: Auto attack (handled automatically by the game)
    -- This is just for debugging
    if DEBUG then
        print("Auto attack is active")
    end

    -- Priority 2: Tranquilizing Shot if target is enraged and not on cooldown
    local targetEnraged = GetBuff("target", "Enrage") or GetBuff("target", "Berserker Rage") or GetBuff("target", "Frenzy") or GetBuff("target", "Rage")
    if targetEnraged and not OnCooldown("Tranquilizing Shot") and IsUsable("Tranquilizing Shot") then
        if DEBUG then
            print("Target is enraged, casting Tranquilizing Shot")
        end
        if Cast("Tranquilizing Shot") then
            return
        end
    end

    -- Priority 3: Hunter's Mark if not on target
    local hasHuntersMark = GetBuff("target", "Hunter's Mark")
    if not hasHuntersMark and not OnCooldown("Hunter's Mark") then
        if DEBUG then
            print("No Hunter's Mark on target, applying Hunter's Mark")
        end
        if Cast("Hunter's Mark") then
            return
        end
    end

    -- Priority 4: Serpent Sting if not on target and mana > 50%
    -- local hasSerpentSting = GetBuff("target", "Serpent Sting")
    -- if not hasSerpentSting and manaPercent > 0.5 and not OnCooldown("Serpent Sting") then
    --     if DEBUG then
    --         print("No Serpent Sting on target and mana > 50%, applying Serpent Sting")
    --     end
    --     if Cast("Serpent Sting") then
    --         return
    --     end
    -- end

    -- -- Priority 5: Bestial Wrath if available
    if not OnCooldown("Bestial Wrath") and IsUsable("Bestial Wrath") then
        if DEBUG then
            print("Bestial Wrath available, casting Bestial Wrath")
        end
        if Cast("Bestial Wrath") then
            return
        end
    end

    -- -- Priority 6: Quel'dorei Meditation if mana < 50%
    -- if manaPercent < 0.5 and not OnCooldown("Quel'dorei Meditation") and IsUsable("Quel'dorei Meditation") then
    --     if DEBUG then
    --         print("Mana < 50%, casting Quel'dorei Meditation")
    --     end
    --     if Cast("Quel'dorei Meditation") then
    --         return
    --     end
    -- end

    -- Priority 7: Steady Shot as filler (has cast time)
    -- Only cast if we have enough time before next auto attack (Steady Shot has ~1s cast time)
    if not OnCooldown("Steady Shot") then
        -- Check if we have enough time for Steady Shot (1 second cast time)

        -- Cast Steady Shot during reloading phase (when we have time)
        if reloadElapsedTime < 0.3  then
            if DEBUG then
                print("Using Steady Shot as filler (during reload)")
            end
            if Cast("Steady Shot") then
                return
            end
        end
    end

    if DEBUG then
        print("No actions to perform, waiting for next auto attack")
    end
end

-- Function to track auto attack timing
function TrackAutoAttack()
    local currentTime = GetTime()
    CurrentState.lastAutoAttack = currentTime
    
    if CurrentState.debugEnabled then
        print("Auto attack detected at: " .. string.format("%.2f", currentTime))
    end
end

-- Update function to handle state transitions (called periodically)
function UpdateAutoShotState()
    if not CurrentState.isShooting and not CurrentState.isReloading then
        return
    end
    
    local currentTime = GetTime()
    
    -- Check if shooting phase is complete
    if CurrentState.isShooting then
        local shootElapsed = currentTime - CurrentState.shootStartTime
        if shootElapsed >= _AIMING_TIME then
            -- Transition to reload phase
            CurrentState.isShooting = false
            CurrentState.isReloading = true
            CurrentState.reloadStartTime = currentTime
            
            if CurrentState.debugEnabled then
                print("Shooting phase complete, starting reload")
            end
        end
    end
    
    -- Check if reload phase is complete
    if CurrentState.isReloading then
        local reloadElapsed = currentTime - CurrentState.reloadStartTime
        local reloadTime = CurrentState.rangedSpeed - _AIMING_TIME
        
        if reloadElapsed >= reloadTime then
            -- Start next shot
            CurrentState.isReloading = false
            CurrentState.isShooting = true
            CurrentState.shootStartTime = currentTime
            
            if CurrentState.debugEnabled then
                print("Reload complete, starting next shot")
            end
        end
    end
end