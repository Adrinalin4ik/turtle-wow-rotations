-- Beast Mastery Hunter rotation (MM baseline + BM skills)
-- manageHuntersMark: Hunter's Mark when missing — high prio if target HP > 70%, low if <= 70%
-- useBestialWrath: cast Bestial Wrath when ready
-- petAttack: send pet at current target via PetAttack

function BMHunterDecision(debugEnabled, manageHuntersMark, useBestialWrath, petAttack)
    CurrentState.debugEnabled = debugEnabled
    local DEBUG = CurrentState.debugEnabled
    manageHuntersMark = manageHuntersMark and true or false
    useBestialWrath = useBestialWrath and true or false
    petAttack = petAttack and true or false

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

    if petAttack and UnitExists("pet") and not UnitIsDead("pet") and type(PetAttack) == "function" then
        local ok = pcall(function()
            PetAttack("target")
        end)
        if not ok then
            pcall(PetAttack)
        end
        if DEBUG then
            print("PetAttack invoked")
        end
    end

    UpdateAutoShotState()
    UpdateKillCommandState()

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
        if PetHasKillCommandBuff() then
            print("Pet has Kill Command buff")
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

    local aimedOnBar = IsSpellOnActionBar("Aimed Shot")

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

    -- Highest priority: Kill Command
    if IsKillCommandAvailable() then
        if DEBUG then
            print("Casting Kill Command")
        end
        if Cast("Kill Command") then
            return
        end
    end

    if useBestialWrath and not OnCooldown("Bestial Wrath") and IsUsable("Bestial Wrath") then
        if not GetBuff("player", "Bestial Wrath") then
            if DEBUG then
                print("Casting Bestial Wrath")
            end
            if Cast("Bestial Wrath") then
                return
            end
        end
    end

    if tryHuntersMarkHighPriority() then
        return
    end

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

    if not OnCooldown("Arcane Shot") and IsUsable("Arcane Shot") then
        if DEBUG then
            print("Casting Arcane Shot")
        end
        if Cast("Arcane Shot") then
            return
        end
    end

    if aimedOnBar then
        local hasLockAndLoad = GetBuff("player", "Lock and Load")
        if hasLockAndLoad and not OnCooldown("Aimed Shot") and IsUsable("Aimed Shot") then
            if DEBUG then
                print("Casting Aimed Shot (Lock and Load)")
            end
            if Cast("Aimed Shot") then
                return
            end
        end

        if not OnCooldown("Aimed Shot") and IsUsable("Aimed Shot") then
            if DEBUG then
                print("Casting Aimed Shot")
            end
            if Cast("Aimed Shot") then
                return
            end
        end
    elseif DEBUG and GetBuff("player", "Lock and Load") then
        print("Skipping Aimed Shot (not on action bar — talent not taken?)")
    end

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

function IsKillCommandAvailable()
    return not OnCooldown("Kill Command") and IsUsable("Kill Command")
end

function PetHasKillCommandBuff()
    if not UnitExists("pet") then
        return false
    end
    return GetBuff("pet", "Kill Command")
end

function UpdateKillCommandState()
    if not CurrentState then
        return
    end
    local hasPetBuff = PetHasKillCommandBuff()
    if not hasPetBuff and CurrentState.killCommandActive then
        CurrentState.killCommandActive = false
        CurrentState.critsRemaining = 0
        if CurrentState.debugEnabled then
            print("Kill Command buff expired (detected via pet buff check)")
        end
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
