std = 'lua51'

ignore = {
	'212', -- unused argument
}

read_globals = {
    -- Lua
	string = {fields = {'join', 'split', 'trim', 'format'}},
	bit = {fields = {'band'}},

    -- Libs
    'LibStub',

    -- FrameXML
	'ResistTrackerFrame',
	'ResistTrackerFrame_BodyFrame_SessionTotalFontString',
	'ResistTrackerFrame_BodyFrame_SessionResistCountFontString',
    'ResistTrackerFrame_ClassResistsFrame',
    'ResistTrackerFrame_HeaderFrame_ClassNameFontString',

	-- WoW
    'COMBATLOG_OBJECT_AFFILIATION_MINE',

    'CombatLogGetCurrentEventInfo',
	'GetSpellInfo',
    'InterfaceOptionsFrame_OpenToCategory',
    'PlaySound',
    'PlaySoundFile',
	'UnitClass',
}