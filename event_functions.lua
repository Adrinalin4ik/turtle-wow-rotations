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
            "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"
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
    
    -- Handle combat events for dodge/parry detection
    if eventType == "CHAT_MSG_COMBAT_SELF_MISSES" or 
       eventType == "CHAT_MSG_SPELL_SELF_DAMAGE" or
       eventType == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
        
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
    
    if CurrentState and CurrentState.debugEnabled then
        print("=== OnEvent() completed ===")
    end
end

function OnUpdate()
    -- This function is called every frame update
    -- Currently not used, but available for future features
    -- such as periodic checks, timers, etc.
end 