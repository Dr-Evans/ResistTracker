local SpellID = {
    EntanglingRoots = 26989,
    Cyclone = 33786,
    CheapShot = 1833,
    KidneyShot = 8643
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

local Event = {COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED"}

local CombatLogSubEvent = {
    SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS",
    SPELL_MISSED = "SPELL_MISSED"
}

local sessionAttemptCount = 0
local sessionResistCount = 0
local spellResistCountFontStrings = {}

-- TODO: Need to address other ranks that have different spell IDs
local trackedSpellCounts = {
    [Class.WARRIOR] = {},
    [Class.PALADIN] = {},
    [Class.SHAMAN] = {},
    [Class.HUNTER] = {},
    [Class.ROGUE] = {
        [SpellID.CheapShot] = {resistCount = 0, totalCount = 0},
        [SpellID.KidneyShot] = {resistCount = 0, totalCount = 0}
    },
    [Class.DRUID] = {
        [SpellID.EntanglingRoots] = {resistCount = 0, totalCount = 0},
        [SpellID.Cyclone] = {resistCount = 0, totalCount = 0}
    },
    [Class.WARLOCK] = {},
    [Class.MAGE] = {},
    [Class.PRIEST] = {}
}

local GetTrackedSpellIDs = function()
    local _, className = UnitClass("player")

    local trackedSpellIDs = {}
    local i = 1
    for trackedSpellID, _ in pairs(trackedSpellCounts[className]) do
        trackedSpellIDs[i] = trackedSpellID

        i = i + 1
    end

    return trackedSpellIDs
end

local GetTrackedSpellResistCount = function(spellID)
    local _, className = UnitClass("player")

    local classSpellCounts = trackedSpellCounts[className][spellID]

    if (classSpellCounts) then return classSpellCounts.resistCount end
end

local GetTrackedSpellTotalCount = function(spellID)
    local _, className = UnitClass("player")

    local classSpellCounts = trackedSpellCounts[className][spellID]

    if (classSpellCounts) then return classSpellCounts.totalCount end
end

local SetTrackedSpellResistCount = function(spellID, resistCount)
    local _, className = UnitClass("player")

    local spellCounts = trackedSpellCounts[className][spellID]

    if (spellCounts) then spellCounts.resistCount = resistCount end
end

local SetTrackedSpellTotalCount = function(spellID, totalCount)
    local _, className = UnitClass("player")

    local spellCounts = trackedSpellCounts[className][spellID]

    if (spellCounts) then spellCounts.totalCount = totalCount end
end

-- Ace 3.0
ResistTracker = LibStub("AceAddon-3.0"):NewAddon("ResistTracker",
                                                 "AceConsole-3.0",
                                                 "AceEvent-3.0")

local options = {
    name = "ResistTracker",
    handler = ResistTracker,
    type = "group",
    args = {
        msg = {
            type = "toggle",
            name = "Show class name",
            desc = "Whether to show the class name",
            get = "GetClassNameEnabled",
            set = "SetClassNameEnabled"
        }
    }
}

function ResistTracker:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ResistTracker", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
                            "ResistTracker", "ResistTracker")

    local prevFontString

    for _, classSpellID in pairs(GetTrackedSpellIDs()) do
        -- Create ClassResist Layer
        local spellResistSpellFontString =
            ResistTrackerFrame_ClassResistsFrame:CreateFontString(nil,
                                                                  "OVERLAY",
                                                                  "GameFontHighlight")

        spellResistSpellFontString:SetPoint("TOPLEFT", prevFontString)
        if (prevFontString) then
            spellResistSpellFontString:SetPoint("TOPLEFT", prevFontString,
                                                "BOTTOMLEFT")
        else
            spellResistSpellFontString:SetPoint("TOPLEFT")
        end

        prevFontString = spellResistSpellFontString

        spellResistCountFontStrings[classSpellID] = spellResistSpellFontString
    end
end

function ResistTracker:OnEnable()
    self:RegisterEvent(Event.COMBAT_LOG_EVENT_UNFILTERED, function()
        local _, subevent = CombatLogGetCurrentEventInfo()

        if (subevent == CombatLogSubEvent.SPELL_CAST_SUCCESS) then
            self:HandleSpellCastSuccess(CombatLogGetCurrentEventInfo())
        elseif (subevent == CombatLogSubEvent.SPELL_MISSED) then
            self:HandleSpellMissed(CombatLogGetCurrentEventInfo())
        end
    end)
end

function ResistTracker:GetClassNameEnabled() return self.classNameEnabled end

function ResistTracker:SetClassNameEnabled(_, value)
    self.classNameEnabled = value
end

function ResistTracker:HandleSpellCastSuccess(timestamp, subevent, hideCaster,
                                              sourceGUID, sourceName,
                                              sourceFlags, sourceRaidFlags,
                                              destGUID, destName, destFlags,
                                              destRaidFlags, spellID, spellName,
                                              spellSchool)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine) then
        local currentTotalCount = GetTrackedSpellTotalCount(spellID)
        if (currentTotalCount) then
            sessionAttemptCount = sessionAttemptCount + 1

            SetTrackedSpellTotalCount(spellID, currentTotalCount + 1)
        end
    end
end

function ResistTracker:HandleSpellMissed(timestamp, subevent, hideCaster,
                                         sourceGUID, sourceName, sourceFlags,
                                         sourceRaidFlags, destGUID, destName,
                                         destFlags, destRaidFlags, spellID,
                                         spellName, spellSchool, missType,
                                         isOffHand, amountMissed, critical)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine and missType == MissType.RESIST) then
        local currentResistCount = GetTrackedSpellResistCount(spellID)
        if (currentResistCount) then
            sessionResistCount = sessionResistCount + 1

            SetTrackedSpellResistCount(spellID, currentResistCount + 1)
        end
    end
end

ResistTrackerFrame:SetScript("OnUpdate", function(self)
    local _, classEnum = UnitClass("player")
    ResistTrackerFrame_HeaderFrame_ClassNameFontString:SetText(classEnum)

    ResistTrackerFrame_BodyFrame_SessionTotalFontString:SetText(string.format(
                                                                    "Stun Attempts: %d",
                                                                    sessionAttemptCount))

    local sessionResistCountPercent = 0
    if sessionResistCount ~= 0 then
        sessionResistCountPercent = sessionResistCount * 100 /
                                        sessionAttemptCount
    end
    ResistTrackerFrame_BodyFrame_SessionResistCountFontString:SetText(
        string.format("Stun Resists: %d (%.f%%)", sessionResistCount,
                      sessionResistCountPercent))

    for spellID, fontString in pairs(spellResistCountFontStrings) do
        local spellName = GetSpellInfo(spellID)
        local spellResistCount = GetTrackedSpellResistCount(spellID)
        local spellTotalCount = GetTrackedSpellTotalCount(spellID)

        local spellResistPercent = 0
        if spellResistCount ~= 0 then
            spellResistPercent = spellResistCount * 100 / spellTotalCount
        end
        fontString:SetText(string.format("%s Resists: %d (%.f%%)", spellName,
                                         spellResistCount, spellResistPercent))
    end
end)

ResistTrackerFrame:SetScript("OnMouseDown",
                             function(self) self:StartMoving() end)
ResistTrackerFrame:SetScript("OnMouseUp",
                             function(self) self:StopMovingOrSizing() end)
