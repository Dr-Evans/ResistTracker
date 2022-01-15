-- Need to address other ranks
local RogueStun = {
    CheapShot = 1833,
    KidneyShot = 8643,
}

ResistTrackerFrame.sessionCount = 0
ResistTrackerFrame.sessionResistCount = 0
ResistTrackerFrame.rogueSessionResistCount = {
    [RogueStun.CheapShot] = 0,
    [RogueStun.KidneyShot] = 0
}

local Event = {
    COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED"
}

local CombatLogSubEvent = {
    SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS",
    SPELL_MISSED = "SPELL_MISSED"
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

ResistTrackerFrame:RegisterEvent(Event.COMBAT_LOG_EVENT_UNFILTERED)
ResistTrackerFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == Event.COMBAT_LOG_EVENT_UNFILTERED) then
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
    ResistTrackerFrame_ClassName:SetText(localizedClass)

    ResistTrackerFrame_SessionCount:SetText(self.sessionCount)
    ResistTrackerFrame_SessionResistCount:SetText(self.sessionResistCount)
    --
    --for classResistSpellID, count in pairs(ResistTrackerFrame.rogueSessionResistCount) do
    --    -- Create ClassResist Layer
    --    local fontString = ResistTrackerFrame_ClassResists:CreateFontString()
    --
    --    local spellName = GetSpellInfo(classResistSpellID)
    --
    --    fontString:SetFontObject("GameTooltipTextSmall")
    --    fontString:SetText(spellName .. " Resist : " .. count)
    --end
end)

ResistTrackerFrame:SetScript("OnMouseDown", function(self, ...)
    self:StartMoving()
end)
ResistTrackerFrame:SetScript("OnMouseUp", function(self, ...)
    self:StopMovingOrSizing()
end)


