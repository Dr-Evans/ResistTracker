local _, addonNamespace = ...
local UUID = addonNamespace.UUID
local Pagination = addonNamespace.Pagination

local InstanceDB = {
    ByGUID = {}, -- string to obj table
    ByTimestamp = {} -- array
}

local Sort = {TIMESTAMP = "TIMESTAMP"}
local Direction = {ASC = "ASC", DESC = "DESC"}

function InstanceDB:Get(guid) return InstanceDB.ByGUID[guid] end

function InstanceDB:Put(instanceName, instanceID, instanceType, maxPlayers)
    local instance = {
        GUID = UUID(),
        Timestamp = GetTime(),
        InstanceName = instanceName,
        InstanceID = instanceID,
        InstanceType = instanceType,
        MaxPlayers = maxPlayers
    }

    InstanceDB.ByGUID[instance.GUID] = instance
    InstanceDB.ByTimestamp[#InstanceDB.ByTimestamp + 1] = instance

    return instance
end

function InstanceDB:List(limit, sort, direction, paginationToken)
    limit = limit or 100
    sort = sort or Sort.TIMESTAMP
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

    local instancesToIterateOver
    if sort == Sort.TIMESTAMP then
        instancesToIterateOver = InstanceDB.ByTimestamp
    else
        error("Sort " .. sort .. " is not supported")
    end

    local step = 1
    local endIndex = math.min(startIndex + limit, #instancesToIterateOver)
    if direction == Direction.DESC then
        step = -1
        startIndex, endIndex = endIndex, startIndex
    end

    local instances = {}
    for i = startIndex, endIndex, step do
        instances[i - startIndex + 1] = instancesToIterateOver[i]
    end

    local newPaginationToken = nil
    if instancesToIterateOver[endIndex + 1] ~= nil then
        newPaginationToken = Pagination.CreatePaginationToken(sort, direction, endIndex + 1)
    end

    return instances, newPaginationToken
end
