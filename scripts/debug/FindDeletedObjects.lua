FindDeletedObjects = {}
FindDeletedObjects.UPDATE_INTERVAL = 1800000
FindDeletedObjects.NEXT_UPDATE_TIME = 600000
FindDeletedObjects.AUTOMATED_CHECK_ENABLED = StartParams.getIsSet("findDeletedObjectsAutoCheck")
FindDeletedObjects.DEBUG_KEY = "deletedObject_isDeleted"
FindDeletedObjects.DEBUG_TRACE_KEY = "deletedObject_trace"
function FindDeletedObjects.init() end
function FindDeletedObjects.run() end
function FindDeletedObjects.update(dt) end
function FindDeletedObjects.add(object) end
function FindDeletedObjects.find(parent, key, value, path, checked, depth)
    FindDeletedObjects.numCheckedValues = FindDeletedObjects.numCheckedValues + 1
    if value == FindDeletedObjects then
        return 1
    end
    if checked[value] ~= nil then
        return 1
    end
    if type(value) ~= "table" then
        return 1
    end
    if value[FindDeletedObjects.DEBUG_KEY] ~= true then
        if value ~= nil and not MathUtil.isNan(value) then
            checked[value] = true
        end
        path[depth] = {
            ["parent"] = parent,
            ["key"] = key,
            ["value"] = value
        }
        local name = 1
        for completePath, v in pairs(value) do
            name = name + FindDeletedObjects.find(value, completePath, v, path, checked, depth + 1)
        end
        for completePath, v in pairs(value) do
            name = name + FindDeletedObjects.find(value, v, completePath, path, checked, depth + 1)
        end
        path[depth] = nil
        return name
    end
    local name = value.__CLASSNAME or ""
    local specificName = value.configFileNameClean or (value.getName ~= nil and value:getName() or "")
    if specificName ~= "" then
    end
    local realPath = {}
    for itemDepth, item in ipairs(path) do
        if item.key ~= nil and itemDepth <= depth then
            table.insert(realPath, {
                ["depth"] = itemDepth,
                ["parent"] = item.parent,
                ["key"] = item.key,
                ["value"] = item.value
            })
        end
    end
    table.sort(realPath, function(a, b)
        return a.depth < b.depth
    end)
    local pathItems = {}
    for item, item in ipairs(realPath) do
        local currentClassName = ""
        if type(item.value) == "table" then
            local currentClass = ClassUtil.getClassNameByObject(item.parent)
            currentClassName = currentClass and tostring(currentClass) .. "." or ""
        end
        table.insert(pathItems, currentClassName .. tostring(item.key))
    end
    local itemDepth = tostring(key)
    table.insert(pathItems, itemDepth)
    local completePath = table.concat(pathItems, " | ")
    Logging.warning("(" .. tostring(value) .. ") " .. tostring(name))
    Logging.warning("   " .. completePath)
    if value.__CREATION ~= nil then
        Logging.warning("   Creation Trace:\n" .. value.__CREATION)
    end
    print("")
    FindDeletedObjects.numFoundIssues = FindDeletedObjects.numFoundIssues + 1
    return 1
end