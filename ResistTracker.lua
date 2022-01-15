local SpellID = {
    CheapShot = 1833,
    KidneyShot = 8643,
}

local MissType = {
    ABSORB = "ABSORB",
    BLOCK = "BLOCK",
    DEFLECT = "DEFLECT",
    DODGE = "DODGE",
    EVADE = "EVADE",
    IMMUNE = "IMMUNE",
    MISS = "MISS",
    PARRY = "PARRY",
    REFLECT = "REFLECT",
    RESIST = "RESIST"
}

local Class = {
    WARRIOR = "WARRIOR",
    PALADIN = "PALADIN",
    SHAMAN = "SHAMAN",
    HUNTER = "HUNTER",
    ROGUE = "ROGUE",
    DRUID = "DRUID",
    WARLOCK = "WARLOCK",
    MAGE = "MAGE",
    PRIEST = "PRIEST"
}

local sessionAttemptCount = 0
local sessionResistCount = 0

-- TODO: Need to address other ranks that have different spell IDs
local sessionClassSpellCounts = {
    [Class.ROGUE] = {
        [SpellID.CheapShot] = {
            resistCount = 0,
            totalCount = 0,
        },
        [SpellID.KidneyShot] = {
            resistCount = 0,
            totalCount = 0,
        },
    },
}

local GetSpellCounts = function()
    local _, className = UnitClass("player")

    return sessionClassSpellCounts[className]
end

local spellResistCountFontStrings = {}

local Event = {
    COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED",
    ADDON_LOADED = "ADDON_LOADED"
}

local CombatLogSubEvent = {
    SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS",
    SPELL_MISSED = "SPELL_MISSED",
}

local HandleAddonLoaded = function(self)
    local prevFontString

    for classSpellID, _ in pairs(GetSpellCounts()) do
        -- Create ClassResist Layer
        local spellResistSpellFontString = ResistTrackerFrame_ClassResists:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

        spellResistSpellFontString:SetPoint("TOPLEFT", prevFontString)
        if (prevFontString) then
            spellResistSpellFontString:SetPoint("TOPLEFT", prevFontString, "BOTTOMLEFT")
        else
            spellResistSpellFontString:SetPoint("TOPLEFT")
        end

        prevFontString = spellResistSpellFontString

        spellResistCountFontStrings[classSpellID] = spellResistSpellFontString
    end
end

local HandleSpellCastSuccess = function(self, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    local _, className = UnitClass("player")
    local isTrackedClass = sessionClassSpellCounts[className]

    print(isMine)
    print(isTrackedClass)
    if (isMine and isTrackedClass) then
        isTrackedClassSpell = sessionClassSpellCounts[className][spellID]
        if (isTrackedClassSpell) then
            sessionAttemptCount = sessionAttemptCount + 1

            print(sessionClassSpellCounts[className][spellID].totalCount)
            sessionClassSpellCounts[className][spellID].totalCount = sessionClassSpellCounts[className][spellID].totalCount + 1
            print(sessionClassSpellCounts[className][spellID].totalCount)
        end
    end
end

local HandleSpellMissed = function(self, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, missType, isOffHand, amountMissed, critical)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine and missType == MissType.RESIST) then
        spellCounts = GetSpellCounts()[spellID]
        if (spellCounts) then
            sessionResistCount = sessionResistCount + 1

            local _, className = UnitClass("player")
            sessionClassSpellCounts[className][spellID].resistCount = sessionClassSpellCounts[className][spellID].resistCount + 1
        end
    end
end

ResistTrackerFrame:RegisterEvent(Event.ADDON_LOADED)
ResistTrackerFrame:RegisterEvent(Event.COMBAT_LOG_EVENT_UNFILTERED)
ResistTrackerFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if (event == Event.ADDON_LOADED and arg1 == "ResistTracker") then
        HandleAddonLoaded(self)
    elseif (event == Event.COMBAT_LOG_EVENT_UNFILTERED) then
        local _, subevent = CombatLogGetCurrentEventInfo()

        if (subevent == CombatLogSubEvent.SPELL_CAST_SUCCESS) then
            HandleSpellCastSuccess(self, CombatLogGetCurrentEventInfo())
        elseif (subevent == CombatLogSubEvent.SPELL_MISSED) then
            HandleSpellMissed(self, CombatLogGetCurrentEventInfo())
        end
    end
end)

ResistTrackerFrame:SetScript("OnUpdate", function(self, ...)
    local _, classEnum = UnitClass("player")
    ResistTrackerFrame_Header_ClassNameText:SetText(classEnum)

    ResistTrackerFrame_Body_SessionTotalFontString:SetText(string.format("Stun Attempts: %d", sessionAttemptCount))

    local sessionResistCountPercent = 0
    if sessionResistCount ~= 0 then
        sessionResistCountPercent = sessionResistCount * 100 / sessionAttemptCount
    end
    ResistTrackerFrame_Body_SessionResistCountFontString:SetText(string.format("Stun Resists: %d (%.f%%)", sessionResistCount, sessionResistCountPercent))

    for spellID, fontString in pairs(spellResistCountFontStrings) do
        local spellName = GetSpellInfo(spellID)
        local spellResistCount = GetSpellCounts()[spellID].resistCount
        local spellTotalCount = GetSpellCounts()[spellID].totalCount

        local spellResistPercent = 0
        if spellResistCount ~= 0 then
            spellResistPercent = spellResistCount * 100 / spellTotalCount
        end
        fontString:SetText(string.format("%s Resists: %d (%.f%%)", spellName, spellResistCount, spellResistPercent))
    end
end)

ResistTrackerFrame:SetScript("OnMouseDown", function(self, ...)
    self:StartMoving()
end)
ResistTrackerFrame:SetScript("OnMouseUp", function(self, ...)
    self:StopMovingOrSizing()
end)


