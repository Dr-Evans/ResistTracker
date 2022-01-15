-- Need to address other ranks
local SpellID = {
    CheapShot = 1833,
    KidneyShot = 8643,
}

ResistTrackerFrame.sessionCount = 0
ResistTrackerFrame.sessionResistCount = 0
ResistTrackerFrame.rogueSessionResistCount = {
    [SpellID.CheapShot] = 0,
    [SpellID.KidneyShot] = 0
}

ResistTrackerFrame.rogueSessionResistCountFontStrings = {}

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
    for classResistSpellID, count in pairs(self.rogueSessionResistCount) do
        print(classResistSpellID)
        -- Create ClassResist Layer
        local spellNameFontString = ResistTrackerFrame_ClassResists:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        local countFontString = ResistTrackerFrame_ClassResists:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

        local spellName = GetSpellInfo(classResistSpellID)
        spellNameFontString:SetText(spellName .. " Resist: ")
        countFontString:SetText(count) -- this is a little moot as it will always be 0

        spellNameFontString:SetPoint("TOPLEFT", prevFontString)
        if (prevFontString) then
            spellNameFontString:SetPoint("TOPLEFT", prevFontString, "BOTTOMLEFT")
        else
            spellNameFontString:SetPoint("TOPLEFT")
        end

        countFontString:SetPoint("LEFT", spellNameFontString, "RIGHT")

        prevFontString = spellNameFontString

        self.rogueSessionResistCountFontStrings[classResistSpellID] = countFontString
    end
end

local PrintResists = function(self)
    print("Session Count: " .. self.sessionCount)
    print("Session Resist Count: " .. self.sessionResistCount)

    for spellID, count in pairs(self.rogueSessionResistCount) do
        local name = GetSpellInfo(spellID)
        print(name .. " (" .. spellID .. "): " .. count)
    end
end

local HandleSpellCastSuccess = function(self, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0
    local isRougeStun = self.rogueSessionResistCount[spellId]

    if (isMine and isRougeStun) then
        print("SPELL_CAST_SUCCESS DETECTED: " .. spellName .. " " .. spellId)

        self.sessionCount = self.sessionCount + 1

        PrintResists(self)
    end
end

local HandleSpellMissed = function(self, timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, missType, isOffHand, amountMissed, critical)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine and missType == MissType.RESIST) then
        c = self.rogueSessionResistCount[spellId]
        if (c) then
            print("RESIST DETECTED: " .. spellName .. " " .. spellId)

            self.sessionResistCount = self.sessionResistCount + 1
            self.rogueSessionResistCount[spellId] = c + 1

            PrintResists(self)
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

ResistTrackerFrame:SetScript("OnLoad", function(self, ...)
    print("loaded")
end)

ResistTrackerFrame:SetScript("OnUpdate", function(self, ...)
    local localizedClass = UnitClass("player")
    ResistTrackerFrame_Header_ClassNameText:SetText(localizedClass)

    ResistTrackerFrame_Body_SessionCount:SetText(self.sessionCount)
    ResistTrackerFrame_Body_SessionResistCount:SetText(self.sessionResistCount)

    for spellID, fontString in pairs(self.rogueSessionResistCountFontStrings) do
        local resistCount = self.rogueSessionResistCount[spellID]
        if (resistCount) then
            fontString:SetText(self.rogueSessionResistCount[spellID])
        end
    end
end)

ResistTrackerFrame:SetScript("OnMouseDown", function(self, ...)
    self:StartMoving()
end)
ResistTrackerFrame:SetScript("OnMouseUp", function(self, ...)
    self:StopMovingOrSizing()
end)


