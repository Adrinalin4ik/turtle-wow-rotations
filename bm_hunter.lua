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
    
    -- Update Kill Command state based on pet buffs
    UpdateKillCommandState()
    
    -- Use Quiver-style timing logic
    local isMidShot, timeRemaining, midShotElapsedTime = GetSecondsRemainingShoot()
    local isReloading, reloadTimeRemaining, reloadElapsedTime = GetSecondsRemainingReload()
    
    if DEBUG then
        print("Mana: " .. mana .. "/" .. maxMana .. " (" .. string.format("%.1f", manaPercent * 100) .. "%)")
        if isMidShot then
            print("Mid-shot, time remaining: " .. string.format("%.2f", timeRemaining) .. "s")
        elseif isReloading then
            print("Reloading, time remaining: " .. string.format("%.2f", reloadTimeRemaining) .. "s")
        else
            print("Ready to cast spells")
        end
        
        -- Debug pet ability states
        if CurrentState.killCommandActive then
            print("Kill Command active! Crits remaining: " .. CurrentState.critsRemaining)
        end
        if IsBaitedShotAvailable() then
            print("Baited Shot available! (Pet crit within 8s)")
        end
        if IsPetBiteAvailable() then
            print("Pet Bite available")
        else
            local cooldownRemaining = GetPetBiteCooldownRemaining()
            print("Pet Bite cooldown: " .. string.format("%.1f", cooldownRemaining) .. "s remaining")
        end
        
        -- Show pet autocast status
        if UnitExists("pet") then
            local clawAutoCast = IsAutoCastEnabled("Claw")
            print("Pet Claw Autocast: " .. (clawAutoCast and "ENABLED" or "DISABLED"))
        end
        
        -- Show detailed pet ability states
        ShowPetAbilityStates()
    end

    -- Don't cast if we're in the middle of a shot (aiming phase)
    if isMidShot then
        if DEBUG then
            print("Mid-shot, waiting... (time remaining: " .. string.format("%.2f", timeRemaining) .. "s)")
        end
        return
    end

    -- Priority 1: Auto attack (handled automatically by the game)
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

    -- Priority 4: Kill Command if available (10 sec cooldown, makes next 2 pet abilities crit)
    if IsKillCommandAvailable() then
        if DEBUG then
            print("Kill Command available, casting Kill Command")
        end
        if Cast("Kill Command") then
            return
        end
    end

    -- Priority 5: Baited Shot if available (after pet crit, 8 second window)
    if IsBaitedShotAvailable() and not OnCooldown("Baited Shot") and IsUsable("Baited Shot") then
        if DEBUG then
            print("Baited Shot available after pet crit, casting Baited Shot")
        end
        if Cast("Baited Shot") then
            return
        end
    end

    -- Priority 6: Pet ability management
    -- Control pet ability autocast based on energy levels
    local petEnergy = UnitMana("pet") or 0
    local maxPetEnergy = UnitManaMax("pet") or 1
    local petEnergyPercent = petEnergy / maxPetEnergy
    
    if DEBUG then
        print("Pet Energy: " .. petEnergy .. "/" .. maxPetEnergy .. " (" .. string.format("%.1f", petEnergyPercent * 100) .. "%)")
    end
    
    -- If pet has more than 50% energy, enable Claw autocast for consistent damage
    -- If pet has less than 50% energy, disable autocast to conserve energy for important abilities
    if petEnergyPercent > 0.5 then
        -- Enable Claw autocast for consistent damage output
        if not IsAutoCastEnabled("Claw") then
            if DEBUG then
                print("Pet energy > 50%, enabling Claw autocast")
            end
            EnableAutoCast("Claw")
        end
    else
        -- Disable Claw autocast to conserve energy
        if IsAutoCastEnabled("Claw") then
            if DEBUG then
                print("Pet energy < 50%, disabling Claw autocast to conserve energy")
            end
            DisableAutoCast("Claw")
        end
    end
    
    -- Priority 7: Steady Shot as filler (has cast time)
    -- Only cast if we have enough time before next auto attack (Steady Shot has ~1s cast time)
    if not OnCooldown("Steady Shot") then
        -- Cast Steady Shot during reloading phase (when we have time)
        if reloadElapsedTime < 0.3 then
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

-- Function to display current pet ability states (useful for debugging)
function ShowPetAbilityStates()
    local DEBUG = CurrentState.debugEnabled
    if not DEBUG then return end
    
    print("=== Pet Ability States ===")
    print("Kill Command Active: " .. tostring(IsKillCommandActive()))
    if IsKillCommandActive() then
        print("Crits Remaining: " .. GetKillCommandCritsRemaining())
    end
    
    print("Baited Shot Available: " .. tostring(IsBaitedShotAvailable()))
    if IsBaitedShotAvailable() then
        local timeSinceCrit = GetTime() - (CurrentState.lastPetCrit or 0)
        print("Baited Shot time remaining: " .. string.format("%.1f", 8 - timeSinceCrit) .. "s")
    end
    
    -- Show pet energy status
    if UnitExists("pet") then
        local petEnergy = UnitMana("pet") or 0
        local maxPetEnergy = UnitManaMax("pet") or 1
        local petEnergyPercent = petEnergy / maxPetEnergy
        print("Pet Energy: " .. petEnergy .. "/" .. maxPetEnergy .. " (" .. string.format("%.1f", petEnergyPercent * 100) .. "%)")
        
        -- Show autocast status
        local clawAutoCast = IsAutoCastEnabled("Claw")
        print("Pet Claw Autocast: " .. (clawAutoCast and "ENABLED" or "DISABLED"))
        
        -- Show energy-based autocast recommendation
        if petEnergyPercent > 0.5 then
            print("Autocast Status: Claw should be ENABLED (>50% energy)")
        else
            print("Autocast Status: Claw should be DISABLED (<50% energy)")
        end
    end
    
    print("Pet Bite Available: " .. tostring(IsPetBiteAvailable()))
    if not IsPetBiteAvailable() then
        local cooldownRemaining = GetPetBiteCooldownRemaining()
        print("Pet Bite cooldown: " .. string.format("%.1f", cooldownRemaining) .. "s remaining")
    end
    
    print("Pet Claw Available: " .. tostring(IsPetClawAvailable()))
    print("========================")
end

-- BM Hunter specific helper functions

-- Check if Baited Shot is available (after pet crit)
function IsBaitedShotAvailable()
    if not CurrentState or not CurrentState.lastPetCrit then
        return false
    end
    
    local timeSincePetCrit = GetTime() - CurrentState.lastPetCrit
    -- Baited Shot is available for 8 seconds after pet crit
    return timeSincePetCrit <= 8
end

-- Check if Kill Command is available
function IsKillCommandAvailable()
    return not OnCooldown("Kill Command") and IsUsable("Kill Command")
end

-- Check if pet Bite is available
function IsPetBiteAvailable()
    if not CurrentState or not CurrentState.lastPetBite then
        return true
    end
    
    local timeSinceBite = GetTime() - CurrentState.lastPetBite
    return timeSinceBite >= CurrentState.petBiteCooldown
end

-- Check if pet Claw is available
function IsPetClawAvailable()
    -- Claw has no cooldown, always available
    return true
end

-- Get time remaining until pet Bite is available
function GetPetBiteCooldownRemaining()
    if not CurrentState or not CurrentState.lastPetBite then
        return 0
    end
    
    local timeSinceBite = GetTime() - CurrentState.lastPetBite
    local cooldownRemaining = CurrentState.petBiteCooldown - timeSinceBite
    
    if cooldownRemaining > 0 then
        return cooldownRemaining
    else
        return 0
    end
end

-- Check if Kill Command buff is active
function IsKillCommandActive()
    if not CurrentState then
        return false
    end
    return CurrentState.killCommandActive and CurrentState.critsRemaining > 0
end

-- Get number of crits remaining from Kill Command
function GetKillCommandCritsRemaining()
    if not CurrentState or not CurrentState.killCommandActive then
        return 0
    end
    return CurrentState.critsRemaining
end

-- Check if pet has Kill Command buff
function PetHasKillCommandBuff()
    if not UnitExists("pet") then
        return false
    end
    
    local petName = UnitName("pet")
    if not petName then
        return false
    end
    
    -- Check if pet has the Kill Command buff
    return GetBuff("pet", "Kill Command")
end

-- Update Kill Command state based on pet buffs
function UpdateKillCommandState()
    if not CurrentState then
        return
    end
    
    local hasPetBuff = PetHasKillCommandBuff()
    
    -- If pet no longer has the buff but we think it's active, reset the state
    if not hasPetBuff and CurrentState.killCommandActive then
        CurrentState.killCommandActive = false
        CurrentState.critsRemaining = 0
        if CurrentState.debugEnabled then
            print("Kill Command buff expired (detected via pet buff check)")
        end
    end
end

-- Helper functions for pet autocast control

-- Check if a pet ability has autocast enabled
function IsAutoCastEnabled(abilityName)
    if not UnitExists("pet") then
        return false
    end
    
    -- Get the pet's spell book to find the ability
    local spellID = 1
    local spellName = GetSpellName(spellID, "BOOKTYPE_PET")
    
    while spellName do
        if spellName == abilityName then
            -- Check if this ability has autocast enabled
            local isAutoCast = GetSpellAutocast(spellID, "BOOKTYPE_PET")
            return isAutoCast
        end
        spellID = spellID + 1
        spellName = GetSpellName(spellID, "BOOKTYPE_PET")
    end
    
    return false
end

-- Enable autocast for a pet ability
function EnableAutoCast(abilityName)
    if not UnitExists("pet") then
        return false
    end
    
    local spellID = 1
    local spellName = GetSpellName(spellID, "BOOKTYPE_PET")
    
    while spellName do
        if spellName == abilityName then
            -- Enable autocast for this ability
            SetSpellAutocast(spellID, "BOOKTYPE_PET", true)
            return true
        end
        spellID = spellID + 1
        spellName = GetSpellName(spellID, "BOOKTYPE_PET")
    end
    
    return false
end

-- Disable autocast for a pet ability
function DisableAutoCast(abilityName)
    if not UnitExists("pet") then
        return false
    end
    
    local spellID = 1
    local spellName = GetSpellName(spellID, "BOOKTYPE_PET")
    
    while spellName do
        if spellName == abilityName then
            -- Disable autocast for this ability
            SetSpellAutocast(spellID, "BOOKTYPE_PET", false)
            return true
        end
        spellID = spellID + 1
        spellName = GetSpellName(spellID, "BOOKTYPE_PET")
    end
    
    return false
end

-- Function to reset pet crit tracking (useful for debugging or resetting state)
function ResetPetCritTracking()
    CurrentState.lastPetCrit = 0
    CurrentState.killCommandActive = false
    CurrentState.critsRemaining = 0
    CurrentState.lastPetBite = 0
    CurrentState.lastPetClaw = 0
    
    if CurrentState.debugEnabled then
        print("Pet crit tracking reset")
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