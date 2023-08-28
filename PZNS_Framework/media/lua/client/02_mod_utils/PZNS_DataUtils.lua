local PZNS_DataUtils = {}


local insert = table.insert
---@param o number|boolean|string|table object to serialize
---@return string str result string
local function serialize(o, res, _nested, _comma)
    res = res or {}
    _nested = _nested or 0
    local comma
    if _comma then
        comma = ",\n"
    else
        comma = ""
    end
    if type(o) == "number" then
        insert(res, o .. comma)
    elseif type(o) == "boolean" then
        insert(res, tostring(o) .. comma)
    elseif type(o) == "string" then
        insert(res, string.format("%q" .. comma, o))
    elseif type(o) == "table" then
        insert(res, "{\n")
        _nested = _nested + 1
        local spaces = string.rep(" ", _nested * 4)
        for k, v in pairs(o) do
            if type(k) ~= "string" then
                insert(res, spaces .. "[")
                serialize(k, res, _nested, false)
                insert(res, "] = ")
            else
                insert(res, spaces .. k .. " = ")
            end

            serialize(v, res, _nested, true)
        end
        _nested = _nested - 1
        insert(res, string.rep(" ", _nested * 4) .. "}" .. comma)
    else
        print("cannot serialize a " .. type(o))
    end
    return table.concat(res)
end

---comment
---@param fname string Filename to load data from
---@return string|nil res Loaded data
PZNS_DataUtils.load = function(fname, isBinary)
    local res
    local data
    local fileReaderObj = getFileReader(fname, true)
    if not fileReaderObj then
        error('File not found and cannot be created')
    end
    data = ''
    local line = fileReaderObj:readLine()
    while line ~= nil do
        data = data .. line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()
    if not isBinary then
        if data and data ~= '' then
            local status = true
            local obj = loadstring("return" .. data)
            status, res = pcall(obj)
            if not status then
                error('Cannot decode')
            end
        end
    else
        res = data
    end

    return res
end

---comment
---@param fname string Filename to save data to
---@param data table Data to save
PZNS_DataUtils.save = function(fname, data)
    if not data then return end
    local fileWriterObj = getFileWriter(fname, true, false)
    if not fileWriterObj then
        error(string.format('Cannot write to %s', fname))
    end
    local status, serialized = pcall(serialize, data)
    if not status then
        error(string.format('Cannot serialize (%s)', serialized))
    end
    fileWriterObj:write(serialized)
    fileWriterObj:close()
end


return PZNS_DataUtils
