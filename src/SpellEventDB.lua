local _, addonNamespace = ...

--[[
-- SpellEvent --
ID
Timestamp
InstanceID
SpellID
MissType

--]]

---@type table Holds all Spell Events that have occurred
local SpellEventDB = {
    ByID = {}, -- string to obj table
    ByInstanceID = {}, -- string to array table
    ByTimestamp = {} -- array
}

local Sort = {TIMESTAMP = "TIMESTAMP"}

local Direction = {ASC = "ASC", DESC = "DESC"}

local parsePaginationToken = function(paginationToken)
    local splits = {}
    local i = 1
    for value in string.gmatch(paginationToken, "-") do
        splits[i] = value
        i = i + 1
    end

    return splits[1], splits[2], tonumber(splits[3])
end

local createPaginationToken = function(sort, direction, nextIndex)
    return sort .. "-" .. direction .. "-" .. nextIndex
end

local iterateSpellEvents = function(spellEventsToIterateOver, limit, sort, direction,
                                    paginationToken)
    limit = limit or 100
    direction = direction or Direction.DESC

    local startIndex
    if paginationToken ~= nil then
        local paginationTokenSort, paginationTokenDirection, paginationTokenNextIndex =
            parsePaginationToken(paginationToken)
        if paginationTokenSort ~= sort then
            error("Pagination token is invalid with provided sort")
        end

        if paginationTokenDirection ~= direction then
            error("Pagination token is invalid with provided direction")
        end

        startIndex = paginationTokenNextIndex
    end

    local step = 1
    local endIndex = math.min(startIndex + limit, #spellEventsToIterateOver)
    if direction == Direction.DESC then
        step = -1
        startIndex, endIndex = endIndex, startIndex
    end

    local spellEvents = {}
    for i = startIndex, endIndex, step do
        spellEvents[i - startIndex + 1] = spellEventsToIterateOver[i]
    end

    local newPaginationToken = nil
    if spellEventsToIterateOver[endIndex + 1] ~= nil then
        newPaginationToken = createPaginationToken(sort, direction, endIndex + 1)
    end

    return spellEvents, newPaginationToken
end

---Get
---@param id string The ID of the spell event
---@return table The spell event, or nil
function SpellEventDB:Get(id) return SpellEventDB.ByID[id] end

function SpellEventDB:Put(spellEvent)
    SpellEventDB.ByID[spellEvent.ID] = spellEvent

    local spellEventsForInstanceID = SpellEventDB.ByInstanceID[spellEvent.InstanceID]
    if spellEventsForInstanceID == nil then
        -- create
        SpellEventDB.ByInstanceID[spellEvent.InstanceID] = {spellEvent}
    else
        -- append
        spellEventsForInstanceID[#spellEventsForInstanceID + 1] = spellEvent
    end

    SpellEventDB.ByTimestamp[#SpellEventDB.ByTimestamp + 1] = spellEvent
end

function SpellEventDB:List(limit, sort, direction, paginationToken)
    sort = sort or Sort.TIMESTAMP

    local spellEventsToIterateOver
    if sort == Sort.TIMESTAMP then
        spellEventsToIterateOver = SpellEventDB.ByTimestamp
    else
        error("Sort " .. sort .. " is not supported")
    end

    return iterateSpellEvents(spellEventsToIterateOver, limit, sort, direction, paginationToken)
end

function SpellEventDB:ListByInstanceID(instanceID, limit, sort, direction, paginationToken)
    sort = sort or Sort.TIMESTAMP

    local spellEventsForInstanceID = SpellEventDB.ByInstanceID[instanceID]
    if spellEventsForInstanceID == nil then return end

    local spellEventsToIterateOver
    if sort == Sort.TIMESTAMP then
        spellEventsToIterateOver = spellEventsForInstanceID
    else
        error("Sort " .. sort .. " is not supported")
    end

    return iterateSpellEvents(spellEventsToIterateOver, limit, sort, direction, paginationToken)
end

addonNamespace.SpellEventDB = SpellEventDB
