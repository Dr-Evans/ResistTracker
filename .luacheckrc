std = 'lua51'

ignore = {
	'212', -- unused argument
}

read_globals = {
	string = {fields = {'join', 'split', 'trim', 'format'}},
	bit = {fields = {'band'}},

	-- FrameXML
	'ResistTrackerFrame',
	'ResistTrackerFrame_BodyFrame_SessionTotalFontString',
	'ResistTrackerFrame_BodyFrame_SessionResistCountFontString',
    'ResistTrackerFrame_ClassResistsFrame',
    'ResistTrackerFrame_HeaderFrame_ClassNameFontString',

	-- WOW
    'COMBATLOG_OBJECT_AFFILIATION_MINE',

    'CombatLogGetCurrentEventInfo',
	'GetSpellInfo',
	'UnitClass',
}