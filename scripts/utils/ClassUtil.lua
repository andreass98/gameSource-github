ClassUtil = {}
function ClassUtil.getIsValidClassName(className)
    return className:find("[^%w_.]") == nil
end
function ClassUtil.getIsValidIndexName(indexName)
    if type(indexName) ~= "string" then
        printError(string.format("Error: ClassUtil.getIsValidIndexName: string expected, got %s", (type(indexName))))
        printCallstack()
    end
    return indexName ~= nil and (indexName ~= "" and not indexName:find("[^%w_.]")) and true or false
end
function ClassUtil.getClassObject(className)
    local parts = string.split(className, ".")
    local currentTable = _G[parts[1]]
    if type(currentTable) ~= "table" then
        return nil
    end
    local i = 2
    for i = i, #parts do
        currentTable = currentTable[parts[i]]
        if type(currentTable) ~= "table" then
            return nil
        end
    end
    return currentTable
end
function ClassUtil.getClassObjectByObject(object)
    local className = ClassUtil.getClassNameByObject(object)
    if className == nil then
        return nil
    else
        return ClassUtil.getClassObject(className)
    end
end
function ClassUtil.getClassName(classObject)
    for k, v in pairs(_G) do
        if v == classObject then
            return k
        end
    end
    for k, v in pairs(g_modIsLoaded) do
        for k, v in pairs(_G[k]) do
            if v == classObject then
                return k .. "." .. k
            end
        end
    end
    return nil
end
function ClassUtil.getClassNameByObject(object)
    if object == nil or object.class == nil then
        return nil
    end
    local classObject = object:class()
    return ClassUtil.getClassName(classObject)
end
function ClassUtil.getClassModName(className)
    local parts = string.split(className, ".")
    if #parts > 1 then
        return parts[1]
    else
        return nil
    end
end
function ClassUtil.getFunction(functionName)
    local parts = string.split(functionName, ".")
    local numParts = #parts
    local currentTable = _G[parts[1]]
    if numParts > 1 then
        if type(currentTable) ~= "table" then
            return nil
        end
        local i = 2
        for i = i, numParts do
            currentTable = currentTable[parts[i]]
            if i ~= numParts and type(currentTable) ~= "table" then
                return nil
            end
        end
    end
    if type(currentTable) == "function" then
        return currentTable
    else
        return nil
    end
end