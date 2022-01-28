local _, addonNamespace = ...
local UUID = addonNamespace.UUID
local Pagination = addonNamespace.Pagination

---@type table Holds all Spell Events that have occurred
local SpellEventDB = {
    ByGUID = {}, -- string to SpellEvents
    ByInstanceGUID = {}, -- string to array of SpellEvents
    BySessionGUID = {}, -- string to array of SpellEvents
    ByTimestamp = {} -- array of SpellEvents
}

local Sort = {TIMESTAMP = "TIMESTAMP"}
local Direction = {ASC = "ASC", DESC = "DESC"}

local iterateSpellEvents = function(spellEventsToIterateOver, limit, sort, direction,
                                    paginationToken)
    limit = limit or 100
    direction = direction or Direction.DESC

    local startIndex
    if paginationToken ~= nil then
        local paginationTokenSort, paginationTokenDirection, paginationTokenNextIndex =
            Pagination.ParsePaginationToken(paginationToken)
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
        newPaginationToken = Pagination.CreatePaginationToken(sort, direction, endIndex + 1)
    end

    return spellEvents, newPaginationToken
end

---Get
---@param guid string The ID of the spell event
---@return table The spell event, or nil
function SpellEventDB:Get(guid) return SpellEventDB.ByGUID[guid] end

function SpellEventDB:Put(timestamp, instanceGUID, sessionGUID, spellID, spellName, missType)
    local spellEvent = {
        GUID = UUID(),
        Timestamp = timestamp,
        InstanceGUID = instanceGUID,
        SessionGUID = sessionGUID,
        SpellID = spellID,
        SpellName = spellName,
        MissType = missType
    }

    SpellEventDB.ByGUID[spellEvent.GUID] = spellEvent

    local spellEventsForInstanceGUID = SpellEventDB.ByInstanceGUID[spellEvent.InstanceGUID]
    if spellEventsForInstanceGUID == nil then
        -- create
        SpellEventDB.ByInstanceGUID[spellEvent.InstanceGUID] = {spellEvent}
    else
        -- append
        spellEventsForInstanceGUID[#spellEventsForInstanceGUID + 1] = spellEvent
    end

    local spellEventsForSessionGUID = SpellEventDB.BySessionGUID[spellEvent.SessionGUID]
    if spellEventsForSessionGUID == nil then
        -- create
        SpellEventDB.ByInstanceGUID[spellEvent.InstanceGUID] = {spellEvent}
    else
        -- append
        spellEventsForSessionGUID[#spellEventsForSessionGUID + 1] = spellEvent
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

function SpellEventDB:Count() return #SpellEventDB.ByTimestamp end

function SpellEventDB:ListByInstanceGUID(instanceGUID, limit, sort, direction, paginationToken)
    sort = sort or Sort.TIMESTAMP

    local spellEventsForInstanceID = SpellEventDB.ByInstanceGUID[instanceGUID]
    if spellEventsForInstanceID == nil then return end

    local spellEventsToIterateOver
    if sort == Sort.TIMESTAMP then
        spellEventsToIterateOver = spellEventsForInstanceID
    else
        error("Sort " .. sort .. " is not supported")
    end

    return iterateSpellEvents(spellEventsToIterateOver, limit, sort, direction, paginationToken)
end

function SpellEventDB:CountByInstanceGUID(instanceGUID)
    local spellEventsForInstanceID = SpellEventDB.ByInstanceGUID[instanceGUID]
    if spellEventsForInstanceID == nil then return 0 end

    return #spellEventsForInstanceID
end

function SpellEventDB:ListBySessionGUID(sessionGUID, limit, sort, direction, paginationToken)
    sort = sort or Sort.TIMESTAMP

    local spellEventsForSessionID = SpellEventDB.BySessionGUID[sessionGUID]
    if spellEventsForSessionID == nil then return end

    local spellEventsToIterateOver
    if sort == Sort.TIMESTAMP then
        spellEventsToIterateOver = spellEventsForSessionID
    else
        error("Sort " .. sort .. " is not supported")
    end

    return iterateSpellEvents(spellEventsToIterateOver, limit, sort, direction, paginationToken)
end

function SpellEventDB:CountBySessionGUID(sessionGUID)
    local spellEventsForSessionID = SpellEventDB.BySessionGUID[sessionGUID]
    if spellEventsForSessionID == nil then return 0 end

    return #spellEventsForSessionID
end

addonNamespace.SpellEventDB = SpellEventDB
