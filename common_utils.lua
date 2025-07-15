-- Common utility functions for WoW addons

-- Create tooltip for buff checking
local CommonTooltip = CreateFrame("GameTooltip", "CommonTooltip", UIParent, "GameTooltipTemplate")

-- Spell to action slot mapping (populated on addon load)
local SpellToActionSlot = {}

-- Function to populate spell to action slot mapping
local function PopulateSpellToActionMapping()
    -- Clear existing mapping
    SpellToActionSlot = {}
    
    -- Iterate through all spell book slots to get spell names and textures
    local spellBookSpells = {}
    local spellID = 1
    local spellName = GetSpellName(spellID, "BOOKTYPE_SPELL")
    
    while spellName do
        local spellTexture = GetSpellTexture(spellID, "BOOKTYPE_SPELL")
        if spellTexture then
            spellBookSpells[spellName] = spellTexture
        end
        spellID = spellID + 1
        spellName = GetSpellName(spellID, "BOOKTYPE_SPELL")
    end
    
    -- Iterate through all action slots to find matching spells
    for slot = 1, 120 do  -- Check all possible action slots
        local actionTexture = GetActionTexture(slot)
        if actionTexture then
            -- Find which spell this action slot corresponds to
            for spellName, spellTexture in pairs(spellBookSpells) do
                if actionTexture == spellTexture then
                    SpellToActionSlot[spellName] = slot
                    break
                end
            end
        end
    end
    
    if CurrentState.debugEnabled then
        print("Spell to action slot mapping populated:")
        for spellName, slot in pairs(SpellToActionSlot) do
            print("  " .. spellName .. " -> slot " .. slot)
        end
    end
end

-- Function to check if a spell is usable
function IsUsable(spellName)
    if spellName == 'Battle Stance' or spellName == 'Berserker Stance' or spellName == 'Defensive Stance' then
        return true
    end

    local actionSlot = SpellToActionSlot[spellName]
    if not actionSlot then
        -- If we don't have a mapping for this spell, try to populate it now
        PopulateSpellToActionMapping()
        actionSlot = SpellToActionSlot[spellName]
    end
    
    if actionSlot then
        local isUsable, noMana = IsUsableAction(actionSlot)
        return isUsable
    end
    
    return false
end

-- Populate spell mapping when addon loads
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function()
    PopulateSpellToActionMapping()
end)

-- Create a frame to track dodge and parry events
local dodgeFrame = CreateFrame("Frame")
dodgeFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
dodgeFrame:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
dodgeFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_COMBAT_SELF_MISSES" or event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
        if string.find(arg1, "dodge") then
            CurrentState.lastDodge = GetTime()
        elseif string.find(arg1, "parry") then
            CurrentState.lastParry = GetTime()
        end
    end
end)

-- Helper function to check buffs and debuffs
function GetBuff(name, buff, stacks)
    local a = 1
    while UnitBuff(name, a) do
        local _, s = UnitBuff(name, a)
        CommonTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        CommonTooltip:ClearLines()
        CommonTooltip:SetUnitBuff(name, a)
        local text = CommonTooltipTextLeft1:GetText()
        if text == buff then 
            if stacks == 1 then
                return s
            else
                return true 
            end
        end
        a = a + 1
    end
    a = 1
    while UnitDebuff(name, a) do
        local _, s = UnitDebuff(name, a)
        CommonTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        CommonTooltip:ClearLines()
        CommonTooltip:SetUnitDebuff(name, a)
        local text = CommonTooltipTextLeft1:GetText()
        if text == buff then 
            if stacks == 1 then
                return s
            else
                return true 
            end
        end
        a = a + 1
    end    
    return false
end

-- Helper function to check if a spell is on cooldown
function OnCooldown(Spell)
    if Spell then
        local spellID = 1
        local spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
        while (spell) do    
            if Spell == spell then
                if GetSpellCooldown(spellID, "BOOKTYPE_SPELL") == 0 then
                    return false
                else
                    return true
                end
            end
            spellID = spellID+1
            spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
        end
    end
end

-- Helper function to check if a spell was successfully applied
function IsApplied(spellName, timeToReset)
    timeToReset = timeToReset or 10  -- Default 10 seconds if not specified
    local currentTime = GetTime()
    
    -- Check if spell was cast recently
    if CurrentState.skillCastTimes[spellName] then
        local castTime = CurrentState.skillCastTimes[spellName]
        local timeSinceCast = currentTime - castTime
        
        -- Check if we're within the valid time window
        if GetBuff("target", spellName) or timeSinceCast > 0.5 and timeSinceCast < timeToReset then
            -- Check if the debuff is actually applied
            return true
        elseif timeSinceCast > timeToReset then
            return false
        end
    end
    return false
end

-- Helper function to cast spells with stance management
function Cast(spellName, requiredStance)
    local DEBUG = CurrentState.debugEnabled
    local _, _, isBattleStance = GetShapeshiftFormInfo(1)
    local _, _, isDefensiveStance = GetShapeshiftFormInfo(2)
    local _, _, isBerserkerStance = GetShapeshiftFormInfo(3)
    -- Check if spell is on cooldown
    if OnCooldown(spellName) then
        if DEBUG then
            print(spellName .. " is on cooldown")
        end
        return false
    end

    -- Check if we need to switch stance
    if requiredStance == "Battle" and not isBattleStance then
        if DEBUG then
            print("Switching to Battle Stance for " .. spellName)
        end
        CastSpellByName("Battle Stance")
        return false
    elseif requiredStance == "Berserker" and not isBerserkerStance then
        if DEBUG then
            print("Switching to Berserker Stance for " .. spellName)
        end
        CastSpellByName("Berserker Stance")
        return false
    end

    -- Check if spell is usable (includes energy, rage, mana checks)
    if not IsUsable(spellName) then
        if DEBUG then
            print(spellName .. " is not usable (insufficient resources)")
        end
        return false
    end

    -- Cast the spell
    if DEBUG then
        print("Casting " .. spellName)
    end
    CastSpellByName(spellName)
    
    -- Record the cast time
    CurrentState.skillCastTimes[spellName] = GetTime()
    
    return true
end

-- Helper function to count nearby enemies
function CountNearbyEnemies()
    local uniqueEnemies = {}
    local count = 0
    
    -- Helper function to add unique enemy
    local function addUniqueEnemy(unit)
        if UnitExists(unit) and UnitCanAttack("player", unit) and UnitIsVisible(unit) then
            local name = UnitName(unit)
            if name and not uniqueEnemies[name] then
                uniqueEnemies[name] = true
                count = count + 1
            end
        end
    end
    
    -- Check main target
    addUniqueEnemy("target")
    
    -- Check target's target
    addUniqueEnemy("targettarget")
    
    -- Check if we're in combat
    if UnitAffectingCombat("player") then
        -- Check party members' targets
        for i = 1, GetNumPartyMembers() do
            addUniqueEnemy("party" .. i .. "target")
        end
        
        -- Check if we're in a raid
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                addUniqueEnemy("raid" .. i .. "target")
            end
        end
    end
    
    if DEBUG then
        print("Enemy count details:")
        print("Target exists: " .. tostring(UnitExists("target")))
        print("Target's target exists: " .. tostring(UnitExists("targettarget")))
        print("In combat: " .. tostring(UnitAffectingCombat("player")))
        print("Party members: " .. GetNumPartyMembers())
        print("Raid members: " .. GetNumRaidMembers())
        print("Unique enemies: " .. count)
    end
    
    return count
end

-- Helper function to check target resistance to magic schools
function GetTargetResistance(magicSchool)
    if not UnitExists("target") then
        return 0
    end
    
    local resistanceIndex = 0
    if magicSchool == "Physical" then
        resistanceIndex = 0
    elseif magicSchool == "Holy" then
        resistanceIndex = 1
    elseif magicSchool == "Fire" then
        resistanceIndex = 2
    elseif magicSchool == "Nature" then
        resistanceIndex = 3
    elseif magicSchool == "Frost" then
        resistanceIndex = 4
    elseif magicSchool == "Shadow" then
        resistanceIndex = 5
    elseif magicSchool == "Arcane" then
        resistanceIndex = 6
    else
        return 0
    end
    
    local base, total, bonus, minus = UnitResistance("target", resistanceIndex)
    local totalResistance = total or 0

    if CurrentState.debugEnabled then
        print("Target " .. magicSchool .. " Resistance: " .. totalResistance)
    end
    
    return totalResistance
end

-- Helper function to detect mob type and check if it can bleed
function CanTargetBleed()
    if not UnitExists("target") then
        return true  -- Default to true if no target
    end
    
    local creatureType = GetTargetCreatureType()
    
    -- Check for creature types that can't bleed
    if creatureType == "Elemental" or 
       creatureType == "Mechanical" or 
       creatureType == "Undead" or
       creatureType == "Demon" or
       creatureType == "Dragonkin" then
        
        if CurrentState.debugEnabled then
            print("Target cannot bleed - Creature Type: " .. creatureType)
        end
        return false
    end
    
    if CurrentState.debugEnabled then
        print("Target can bleed - Creature Type: " .. creatureType)
    end
    
    return true
end

-- Helper function to get target's creature type
function GetTargetCreatureType()
    if not UnitExists("target") then
        return "Unknown"
    end
    
    local creatureType = UnitCreatureType("target")
    if creatureType then
        return creatureType
    end
    
    -- Fallback to tooltip scanning
    CommonTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    CommonTooltip:ClearLines()
    CommonTooltip:SetUnit("target")
    
    for i = 1, CommonTooltip:NumLines() do
        local line = getglobal("CommonTooltipTextLeft" .. i)
        if line then
            local text = line:GetText()
            if text then
                -- Look for creature type patterns
                if string.find(text, "Elemental") then
                    return "Elemental"
                elseif string.find(text, "Mechanical") then
                    return "Mechanical"
                elseif string.find(text, "Undead") then
                    return "Undead"
                elseif string.find(text, "Demon") then
                    return "Demon"
                elseif string.find(text, "Dragonkin") then
                    return "Dragonkin"
                elseif string.find(text, "Humanoid") then
                    return "Humanoid"
                elseif string.find(text, "Beast") then
                    return "Beast"
                elseif string.find(text, "Giant") then
                    return "Giant"
                end
            end
        end
    end
    
    return "Unknown"
end