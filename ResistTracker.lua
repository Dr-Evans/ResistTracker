local SpellID = {
    CheapShot = 1833,
    KidneyShot = 8643,
}

local sessionTotal = 0
local sessionResistCount = 0

-- TODO: Need to address other ranks that have different spell IDs
local rogueSessionTotal = {
    [SpellID.CheapShot] = 0,
    [SpellID.KidneyShot] = 0
}

local rogueSessionResistCount = {
    [SpellID.CheapShot] = 0,
    [SpellID.KidneyShot] = 0
}

local rogueSessionResistCountFontStrings = {}

local Event = {
    COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED",
    ADDON_LOADED = "ADDON_LOADED"
}

local CombatLogSubEvent = {
    SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS",
    SPELL_MISSED = "SPELL_MISSED",
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

local HandleAddonLoaded = function(self)

    local prevFontString
    for classResistSpellID, _ in pairs(rogueSessionResistCount) do
        -- Create ClassResist Layer
        local classSessionResistSpellFontString = ResistTrackerFrame_ClassResists:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

        local spellName = GetSpellInfo(classResistSpellID)

        classSessionResistSpellFontString:SetPoint("TOPLEFT", prevFontString)
        if (prevFontString) then
            classSessionResistSpellFontString:SetPoint("TOPLEFT", prevFontString, "BOTTOMLEFT")
        else
            classSessionResistSpellFontString:SetPoint("TOPLEFT")
        end

        prevFontString = classSessionResistSpellFontString

        rogueSessionResistCountFontStrings[classResistSpellID] = classSessionResistSpellFontString
    end
end

local HandleSpellCastSuccess = function(self, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0
    local isRougeStun = rogueSessionTotal[spellId]

    if (isMine and isRougeStun) then
        sessionTotal = sessionTotal + 1
        rogueSessionTotal[spellId] = rogueSessionTotal[spellId] + 1
    end
end

local HandleSpellMissed = function(self, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, missType, isOffHand, amountMissed, critical)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine and missType == MissType.RESIST) then
        c = rogueSessionResistCount[spellId]
        if (c) then
            sessionResistCount = sessionResistCount + 1
            rogueSessionResistCount[spellId] = c + 1

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
    local localizedClass = UnitClass("player")
    ResistTrackerFrame_Header_ClassNameText:SetText(localizedClass)

    ResistTrackerFrame_Body_SessionTotalFontString:SetText(string.format("Session Total: %d", sessionTotal))
    ResistTrackerFrame_Body_SessionResistCountFontString:SetText(string.format("Session Resist: %d (%.f%%)", sessionResistCount, sessionResistCount == 0 and 100 or (sessionResistCount * 100 / sessionTotal)))

    for spellID, fontString in pairs(rogueSessionResistCountFontStrings) do
        local spellName = GetSpellInfo(spellID)
        local spellResistCount = rogueSessionResistCount[spellID]
        local spellTotalCount = rogueSessionTotal[spellID]

        if (spellResistCount) then
            fontString:SetText(string.format("%s Resist: %d (%.f%%)", spellName, spellResistCount, spellResistCount == 0 and 100 or (spellResistCount * 100 / spellTotalCount)))
        end
    end
end)

ResistTrackerFrame:SetScript("OnMouseDown", function(self, ...)
    self:StartMoving()
end)
ResistTrackerFrame:SetScript("OnMouseUp", function(self, ...)
    self:StopMovingOrSizing()
end)


