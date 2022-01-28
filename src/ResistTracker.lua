local _, addonNamespace = ...
local UUID = addonNamespace.UUID
local SpellEventDB = addonNamespace.SpellEventDB
local InstanceDB = addonNamespace.InstanceDB

local SpellID = {EntanglingRoots = 26989, Cyclone = 33786, CheapShot = 1833, KidneyShot = 8643}

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

-- https://wowpedia.fandom.com/wiki/API_IsInInstance
local InstanceType = {
    NONE = "none",
    PVP = "pvp",
    ARENA = "arena",
    PARTY = "party",
    RAID = "raid",
    SCENARIO = "scenario"
}

local Event = {
    ZONE_CHANGED_NEW_AREA = "ZONE_CHANGED_NEW_AREA",
    COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED"
}

local CombatLogSubEvent = {SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS", SPELL_MISSED = "SPELL_MISSED"}

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

local ResistTrackerAddon = LibStub("AceAddon-3.0"):NewAddon("ResistTracker", "AceConsole-3.0",
                                                            "AceEvent-3.0")

local options = {
    type = "group",
    name = "Resist Tracker",
    handler = ResistTrackerAddon,
    args = {
        soundDesc = {
            type = "description",
            name = "These options affect sounds that play on resists.",
            order = 1
        },
        newLine0 = {type = "description", name = "", order = 2},
        shouldPlayResistSoundEffect = {
            type = "toggle",
            name = "Sound on Resist",
            desc = "Play a sound when a resist happens.",
            order = 3,
            get = "GetShouldPlayResistSoundEffect",
            set = "SetShouldPlayResistSoundEffect"
        },
        newLine1 = {type = "description", name = "", order = 4},
        resistSoundEffectID = {
            type = "select",
            name = "Sound Effect",
            desc = "Sound to play",
            order = 5,
            width = 0.8,
            values = {
                -- TODO: Replace IDs with actual files
                ["416"] = "Murloc",
                ["6943"] = "Orc Laugh",
                ["1294"] = "Peasant",
                ["11466"] = "Prepared",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\SadTrombone.mp3"] = "Sad Trombone",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\LosingHorn.mp3"] = "Losing Horn",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\Bruh.mp3"] = "Bruh",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\Waow.mp3"] = "Waow",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\MetalGearAlert.mp3"] = "Metal Gear Alert",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\Sheesh.mp3"] = "Sheesh",
                ["Interface\\AddOns\\ResistTracker\\media\\sounds\\WilhelmScream.mp3"] = "Wilhelm Scream"
            },
            get = "GetResistSoundEffect",
            set = "SetResistSoundEffect"
        },
        testSoundButton = {
            type = "execute",
            name = "Test",
            desc = "Test sound effect.",
            order = 6,
            width = "half",
            func = "OnTestSoundButtonClick"
        }
    }
}

function ResistTrackerAddon:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ResistTracker", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ResistTracker")

    self:RegisterChatCommand("rt", "SlashCommand")
    self:RegisterChatCommand("resisttracker", "SlashCommand")

    self.shouldPlayResistSoundEffect = true
    self.resistSoundEffect = "416"
    self.sessionGUID = UUID()

    local prevFontString

    for _, classSpellID in pairs(GetTrackedSpellIDs()) do
        -- Create ClassResist Layer
        local spellResistSpellFontString = ResistTrackerFrame_ClassResistsFrame:CreateFontString(
                                               nil, "OVERLAY", "GameFontHighlight")

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

function ResistTrackerAddon:OnEnable()
    self:RegisterEvent(Event.COMBAT_LOG_EVENT_UNFILTERED, "HandleCombatLogEventUnfiltered")
    self:RegisterEvent(Event.ZONE_CHANGED_NEW_AREA, "HandleZoneChangedNewArea")
end

function ResistTrackerAddon:SlashCommand(msg)
    if not msg or msg:trim() == "" or string.lower(msg) == SlashCommandMessage.CONFIG then
        self:HandleConfigSlashCommand()
    elseif string.lower(msg) == SlashCommandMessage.RESET then
        self:HandleResetSlashCommand()
    elseif string.lower(msg) == SlashCommandMessage.HELP then
        self:HandleHelpSlashCommand()
    elseif string.lower(msg) == SlashCommandMessage.SHOW then
        self:HandleShowSlashCommand()
    elseif string.lower(msg) == SlashCommandMessage.HIDE then
        self:HandleHideSlashCommand()
    elseif string.lower(msg) == SlashCommandMessage.PLAY then
        self:HandlePlaySlashCommand()
    end
end

function ResistTrackerAddon:HandleConfigSlashCommand()
    -- https://github.com/Stanzilla/WoWUIBugs/issues/89
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function ResistTrackerAddon:HandleResetSlashCommand()
    sessionAttemptCount = 0
    sessionResistCount = 0

    for _, classSpellID in pairs(GetTrackedSpellIDs()) do
        SetTrackedSpellTotalCount(classSpellID, 0)
        SetTrackedSpellResistCount(classSpellID, 0)
    end
end

function ResistTrackerAddon:HandleHelpSlashCommand()
    print([[Resist Tracker
/rt - Open config menu.
/rt help - Print this message.
/rt hide - Hide Resist Tracker.
/rt play - Play current resist sound.
/rt reset - Reset resist counts.
/rt show - Show Resist Tracker.]])
end

function ResistTrackerAddon:HandleShowSlashCommand() ResistTrackerFrame:Show() end

function ResistTrackerAddon:HandleHideSlashCommand() ResistTrackerFrame:Hide() end

function ResistTrackerAddon:HandlePlaySlashCommand()
    if not pcall(PlaySound, self.resistSoundEffect) then PlaySoundFile(self.resistSoundEffect) end
end
function ResistTrackerAddon:GetShouldPlayResistSoundEffect(info)
    return self.shouldPlayResistSoundEffect
end

function ResistTrackerAddon:SetShouldPlayResistSoundEffect(info, value)
    options.args.resistSoundEffectID.disabled = not value
    options.args.testSoundButton.disabled = not value

    self.shouldPlayResistSoundEffect = value
end

function ResistTrackerAddon:GetResistSoundEffect(info) return self.resistSoundEffect end

function ResistTrackerAddon:SetResistSoundEffect(info, value) self.resistSoundEffect = value end

function ResistTrackerAddon:OnTestSoundButtonClick()
    if not pcall(PlaySound, self.resistSoundEffect) then PlaySoundFile(self.resistSoundEffect) end
end

function ResistTrackerAddon:HandleCombatLogEventUnfiltered()
    local _, subevent = CombatLogGetCurrentEventInfo()

    if (subevent == CombatLogSubEvent.SPELL_CAST_SUCCESS) then
        self:HandleSpellCastSuccess(CombatLogGetCurrentEventInfo())
    elseif (subevent == CombatLogSubEvent.SPELL_MISSED) then
        self:HandleSpellMissed(CombatLogGetCurrentEventInfo())
    end
end

function ResistTrackerAddon:HandleSpellCastSuccess(timestamp, subevent, hideCaster, sourceGUID,
                                                   sourceName, sourceFlags, sourceRaidFlags,
                                                   destGUID, destName, destFlags, destRaidFlags,
                                                   spellID, spellName, spellSchool)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine and self.currentArena ~= nil) then
        local currentTotalCount = GetTrackedSpellTotalCount(spellID)
        if (currentTotalCount) then
            sessionAttemptCount = sessionAttemptCount + 1

            SetTrackedSpellTotalCount(spellID, currentTotalCount + 1)
        end

        SpellEventDB:Put(timestamp, self.currentArena.InstanceGUID, self.sessionGUID, spellID,
                         spellName, nil)
    end
end

function ResistTrackerAddon:HandleSpellMissed(timestamp, subevent, hideCaster, sourceGUID,
                                              sourceName, sourceFlags, sourceRaidFlags, destGUID,
                                              destName, destFlags, destRaidFlags, spellID,
                                              spellName, spellSchool, missType, isOffHand,
                                              amountMissed, critical)
    local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0

    if (isMine and self.currentArena ~= nil and missType == MissType.RESIST) then
        local currentResistCount = GetTrackedSpellResistCount(spellID)
        if (currentResistCount) then
            sessionResistCount = sessionResistCount + 1

            SetTrackedSpellResistCount(spellID, currentResistCount + 1)
        end

        SpellEventDB:Put(timestamp, self.currentArena.InstanceGUID, self.sessionGUID, spellID,
                         spellName, missType)
    end
end

function ResistTrackerAddon:HandleZoneChangedNewArea()
    local instanceName, instanceType, _, _, maxPlayers, _, _, instanceID = GetInstanceInfo()

    if (instanceType == InstanceType.ARENA) then
        local instance = InstanceDB:Put(instanceName, instanceID, instanceType, maxPlayers)

        self.currentArena = instance
    elseif (self.currentArena ~= nil) then
        self.currentArena = nil
    end
end

ResistTrackerFrame:SetScript("OnUpdate", function(self)
    local _, classEnum = UnitClass("player")
    ResistTrackerFrame_HeaderFrame_ClassNameFontString:SetText(classEnum)

    ResistTrackerFrame_BodyFrame_SessionTotalFontString:SetText(
        string.format("Stun Attempts: %d", sessionAttemptCount))

    local sessionResistCountPercent = 0
    if sessionResistCount ~= 0 then
        sessionResistCountPercent = sessionResistCount * 100 / sessionAttemptCount
    end
    ResistTrackerFrame_BodyFrame_SessionResistCountFontString:SetText(string.format(
                                                                          "Stun Resists: %d (%.f%%)",
                                                                          sessionResistCount,
                                                                          sessionResistCountPercent))

    for spellID, fontString in pairs(spellResistCountFontStrings) do
        local spellName = GetSpellInfo(spellID)
        local spellResistCount = GetTrackedSpellResistCount(spellID)
        local spellTotalCount = GetTrackedSpellTotalCount(spellID)

        local spellResistPercent = 0
        if spellResistCount ~= 0 then
            spellResistPercent = spellResistCount * 100 / spellTotalCount
        end
        fontString:SetText(string.format("%s Resists: %d (%.f%%)", spellName, spellResistCount,
                                         spellResistPercent))
    end
end)

ResistTrackerFrame:SetScript("OnMouseDown", function(self) self:StartMoving() end)
ResistTrackerFrame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
