function Enum(enum)
    local all = {}
    local names = {}
    local allOrdered = {}
    local allOrderedByName = {}
    for k, v in pairs(enum) do
        if v == 0 then
            Logging.error("Try to create an enum with item value 0. Enums have to be 1-based")
            printCallstack()
        end
        all[k] = v
        names[v] = k
        table.insert(allOrdered, v)
        table.insert(allOrderedByName, k)
    end
    table.sort(allOrdered)
    table.sort(allOrderedByName)
    function enum.getByName(name)
        -- upvalues: (copy) enum
        if name == nil then
            return nil
        else
            name = string.upper(name)
            if ClassUtil.getIsValidIndexName(name) then
                return enum[name]
            else
                return nil
            end
        end
    end
    function enum.getName(id)
        -- upvalues: (copy) names
        return names[id]
    end
    function enum.getAll()
        -- upvalues: (copy) all
        return all
    end
    function enum.getAllOrdered()
        -- upvalues: (copy) allOrdered
        return allOrdered
    end
    function enum.getAllOrderedByName()
        -- upvalues: (copy) allOrderedByName
        return allOrderedByName
    end
    function enum.getAllNames()
        -- upvalues: (copy) names
        return table.concat(names, ", ")
    end
    local numBits = 1
    local k = unpack
    local maxValue = math.max(k(allOrdered)) - 1
    local v = 1
    local k = 1
    for v = v, 31, k do
        if maxValue <= 2 ^ numBits - 1 then
            break
        end
        numBits = numBits + 1
    end
    function enum.getNumBits()
        -- upvalues: (ref) numBits
        return numBits
    end
    function enum.writeStream(streamId, id)
        -- upvalues: (ref) numBits
        streamWriteUIntN(streamId, id - 1, numBits)
    end
    function enum.readStream(streamId)
        -- upvalues: (ref) numBits
        return streamReadUIntN(streamId, numBits) + 1
    end
    function enum.loadFromXMLFile(xmlFile, key)
        -- upvalues: (copy) enum
        local wrapped = false
        if type(xmlFile) == "number" then
            xmlFile = XMLFile.wrap(xmlFile)
            wrapped = true
        end
        local name = xmlFile:getString(key)
        if wrapped then
            xmlFile:delete()
        end
        return enum.getByName(name)
    end
    function enum.saveToXMLFile(xmlFile, key, id)
        -- upvalues: (copy) enum, (copy) allOrdered, (copy) names
        local valueName = enum.getName(id)
        if valueName == nil then
            Logging.warning("Enum.saveToXMLFile(): Unable to get name for value %q, enum:", id)
            for _, v in ipairs(allOrdered) do
                printWarning("    " .. names[v] .. ":" .. v)
            end
            printCallstack()
        else
            local wrapped = false
            if type(xmlFile) == "number" then
                xmlFile = XMLFile.wrap(xmlFile)
                wrapped = true
            end
            xmlFile:setString(key, valueName)
            if wrapped then
                xmlFile:delete()
            end
        end
    end
    function enum.registerXMLPath(schema, path, description, defaultValue, isRequired)
        -- upvalues: (copy) allOrderedByName
        schema:register(XMLValueType.STRING, path, description, defaultValue, isRequired, allOrderedByName)
    end
end