-- Event handler functions for TREventFrame
-- These functions must be defined before combat_helper.xml loads

-- Global reference to the event frame (will be set when XML loads)
TREventFrame = nil

-- Debug function to check frame status
local function DebugFrameStatus()
    if not CurrentState or not CurrentState.debugEnabled then return end
    
    print("=== Frame Debug Info ===")
    print("TREventFrame exists: " .. tostring(TREventFrame ~= nil))
    if TREventFrame then
        print("TREventFrame type: " .. type(TREventFrame))
        print("TREventFrame name: " .. tostring(TREventFrame:GetName()))
    end
    print("CurrentState exists: " .. tostring(CurrentState ~= nil))
    if CurrentState then
        print("CurrentState type: " .. type(CurrentState))
    end
    print("=======================")
end

-- Event handler functions
function OnLoad()
    -- Initialize the addon when it loads
    if CurrentState and CurrentState.debugEnabled then
        print("=== OnLoad() called ===")
    end
    
    -- Set the global reference to the frame
    TREventFrame = _G["TREventFrame"]
    
    DebugFrameStatus()
    
    -- Ensure CurrentState is initialized
    if not CurrentState then
        CurrentState = {
            debugEnabled = false,
            lastDodge = 0,
            lastParry = 0,
            skillCastTimes = {}
        }
        if CurrentState.debugEnabled then
            print("CurrentState initialized")
        end
    end
    
    -- Register only ADDON_LOADED initially - other events will be registered after addon loads
    local success, err = pcall(function()
        TREventFrame:RegisterEvent("ADDON_LOADED")
    end)
    if success then
        if CurrentState and CurrentState.debugEnabled then
            print("Registered ADDON_LOADED event")
        end
    else
        print("Failed to register ADDON_LOADED event: " .. (err or "unknown error"))
    end
    
    if CurrentState and CurrentState.debugEnabled then
        print("=== OnLoad() completed ===")
    end
end

function OnEvent()
    local eventType = event
    local arg1 = arg1
    local arg2 = arg2
    local arg3 = arg3
    local arg4 = arg4
    
    if CurrentState and CurrentState.debugEnabled then
        print("=== OnEvent() called ===")
        print("Event received: " .. tostring(eventType))
        print("Arg1: " .. tostring(arg1))
    end
    
    -- Handle ADDON_LOADED event
    if eventType == "ADDON_LOADED" and arg1 == "turtle-wow-rotations" then
        print("|cff0066ff========================================|r")
        print("|cff0066ff Turtle WoW Rotations system loaded!|r")
        print("|cff0066ff Use your class-specific macros!|r")
        print("|cff0066ff========================================|r")
        
        -- Now register all other events
        local events = {
            "PLAYER_LOGIN",
            "ACTIONBAR_SLOT_CHANGED", 
            "CHAT_MSG_COMBAT_SELF_MISSES",
            "CHAT_MSG_SPELL_SELF_DAMAGE",
            "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
            "CHAT_MSG_COMBAT_SELF_HITS",
            "CHAT_MSG_COMBAT_SELF_DAMAGE",
            "START_AUTOREPEAT_SPELL",
            "STOP_AUTOREPEAT_SPELL",
            "SPELLCAST_STOP",
            "SPELLCAST_DELAYED",
            "SPELLCAST_FAILED",
            "SPELLCAST_INTERRUPTED",
            "ITEM_LOCK_CHANGED"
        }
        
        for _, eventName in ipairs(events) do
            local success, err = pcall(function()
                TREventFrame:RegisterEvent(eventName)
            end)
            if success then
                if CurrentState and CurrentState.debugEnabled then
                    print("Registered event: " .. eventName)
                end
            else
                print("Failed to register event: " .. eventName .. " - " .. (err or "unknown error"))
            end
        end
        
        TREventFrame:UnregisterEvent("ADDON_LOADED")
        if CurrentState and CurrentState.debugEnabled then
            print("=== ADDON_LOADED handled ===")
        end
        return
    end
    
    -- Handle PLAYER_LOGIN and ACTIONBAR_SLOT_CHANGED events
    if eventType == "PLAYER_LOGIN" or eventType == "ACTIONBAR_SLOT_CHANGED" then
        if CurrentState and CurrentState.debugEnabled then
            print("Processing " .. eventType .. " event")
        end
        -- Populate spell to action slot mapping
        PopulateSpellToActionMapping()
        if CurrentState and CurrentState.debugEnabled then
            print("=== " .. eventType .. " handled ===")
        end
        return
    end
    
    -- Handle combat events for dodge/parry detection and auto attack tracking
    if eventType == "CHAT_MSG_COMBAT_SELF_MISSES" or 
       eventType == "CHAT_MSG_SPELL_SELF_DAMAGE" or
       eventType == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" or
       eventType == "CHAT_MSG_COMBAT_SELF_HITS" or
       eventType == "CHAT_MSG_COMBAT_SELF_DAMAGE" then
        
        local message = arg1
        if CurrentState and CurrentState.debugEnabled then
            print("Combat event: " .. eventType .. " - " .. tostring(message))
        end
        
        -- Check for dodge patterns
        if string.find(message, "dodge") then
            CurrentState.lastDodge = GetTime()
            if CurrentState and CurrentState.debugEnabled then
                print("Overpower proc detected! Dodge event: " .. message)
            end
        end
        
        -- Check for parry patterns (for future use)
        if string.find(message, "parry") then
            CurrentState.lastParry = GetTime()
            if CurrentState and CurrentState.debugEnabled then
                print("Parry detected: " .. message)
            end
        end
        
        -- Track auto shot for hunter rotation
        if string.find(message, "hits") or string.find(message, "crits") then
            -- Check if this is an auto attack (not a spell)
            -- if not string.find(message, "spell") and not string.find(message, "ability") then
            --     TrackAutoAttack()
            -- end
            if string.find(message, "Auto Shot") then
                TrackAutoAttack()
            end
        end
        
        -- Additional dodge detection using global strings (if available)
        if getglobal('VSDODGESELFOTHER') and string.find(message, getglobal('VSDODGESELFOTHER')) then
            CurrentState.lastDodge = GetTime()
            if CurrentState and CurrentState.debugEnabled then
                print("Overpower proc detected via global string!")
            end
        end
        
        if getglobal('SPELLDODGEDSELFOTHER') and string.find(message, getglobal('SPELLDODGEDSELFOTHER')) then
            CurrentState.lastDodge = GetTime()
            if CurrentState and CurrentState.debugEnabled then
                print("Overpower proc detected via spell global string!")
            end
        end
        
        if CurrentState and CurrentState.debugEnabled then
            print("=== Combat event handled ===")
        end
    end
    
    -- Handle auto shot events (Quiver-style state machine)
    if eventType == "START_AUTOREPEAT_SPELL" then
        if CurrentState and CurrentState.debugEnabled then
            print("Auto shot started")
        end
        CurrentState.autoShotActive = true
        CurrentState.isShooting = true
        CurrentState.shootStartTime = GetTime()
        CurrentState.rangedSpeed = UnitRangedDamage("player")
    elseif eventType == "STOP_AUTOREPEAT_SPELL" then
        if CurrentState and CurrentState.debugEnabled then
            print("Auto shot stopped")
        end
        CurrentState.autoShotActive = false
        CurrentState.isShooting = false
        CurrentState.isReloading = false
    elseif eventType == "ITEM_LOCK_CHANGED" then
        -- Handle auto shot firing and state transitions
        if CurrentState and CurrentState.autoShotActive then
            if CurrentState.debugEnabled then
                print("Auto shot fired (ITEM_LOCK_CHANGED)")
            end
            
            local currentTime = GetTime()
            
            -- Start reload phase
            CurrentState.isReloading = true
            CurrentState.reloadStartTime = currentTime
            CurrentState.isShooting = false
            
            -- Track for legacy compatibility
            TrackAutoAttack()
        end
    elseif eventType == "SPELLCAST_STOP" then
        -- Handle spell cast interruptions
        if CurrentState and CurrentState.debugEnabled then
            print("Spell cast stopped")
        end
        CurrentState.lastSpellCastStop = GetTime()
        CurrentState.isCasting = false
        
        -- Reset shooting state after spell cast
        if CurrentState.isShooting then
            CurrentState.shootStartTime = GetTime()
        end
    elseif eventType == "SPELLCAST_DELAYED" then
        -- Handle cast pushback
        if CurrentState and CurrentState.debugEnabled then
            print("Spell cast delayed")
        end
    elseif eventType == "SPELLCAST_FAILED" or eventType == "SPELLCAST_INTERRUPTED" then
        -- Handle cast failures
        if CurrentState and CurrentState.debugEnabled then
            print("Spell cast " .. (eventType == "SPELLCAST_FAILED" and "failed" or "interrupted"))
        end
        CurrentState.isCasting = false
        CurrentState.isFiredInstant = false
    end
    
    if CurrentState and CurrentState.debugEnabled then
        print("=== OnEvent() completed ===")
    end
end

function OnUpdate()
    -- This function is called every frame update
    -- Currently not used, but available for future features
    -- such as periodic checks, timers, etc.
end 