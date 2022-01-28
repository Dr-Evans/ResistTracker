local _, addonNamespace = ...

local Pagination = {}

function Pagination.ParsePaginationToken(paginationToken)
    local splits = {}
    local i = 1
    for value in string.gmatch(paginationToken, "-") do
        splits[i] = value
        i = i + 1
    end

    return splits[1], splits[2], tonumber(splits[3])
end

function Pagination.CreatePaginationToken(sort, direction, nextIndex)
    return sort .. "-" .. direction .. "-" .. nextIndex
end

addonNamespace.Pagination = Pagination
