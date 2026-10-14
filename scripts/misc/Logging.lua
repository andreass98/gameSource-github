Logging = {}
local function getFilename(obj)
    local objType = type(obj)
    if objType == "number" then
        return getXMLFilename(obj)
    elseif objType == "table" and (obj.isa ~= nil and obj:isa(XMLFile)) then
        return obj:getFilename()
    elseif objType == "string" and string.endsWith(obj, ".xml") then
        return obj
    else
        return nil
    end
end
function Logging.xmlWarning(xmlFile, warningMessage, ...)
    -- upvalues: (copy) getFilename
    local filename = getFilename(xmlFile)
    printWarning(string.format("  Warning (%s): " .. warningMessage, filename, ...))
end
function Logging.xmlError(xmlFile, errorMessage, ...)
    -- upvalues: (copy) getFilename
    local filename = getFilename(xmlFile)
    printError(string.format("  Error (%s): " .. errorMessage, filename, ...))
end
function Logging.xmlInfo(xmlFile, infoMessage, ...)
    -- upvalues: (copy) getFilename
    local filename = getFilename(xmlFile)
    print(string.format("  Info (%s): " .. infoMessage, filename, ...))
end
function Logging.i3dWarning(node, warningMessage, ...)
    local nodeStr = I3DUtil.getNodeNameAndIndexPath(node)
    printWarning(string.format("  Warning (%s): " .. warningMessage, nodeStr, ...))
end
function Logging.i3dError(node, errorMessage, ...)
    local nodeStr = I3DUtil.getNodeNameAndIndexPath(node)
    printError(string.format("  Error (%s): " .. errorMessage, nodeStr, ...))
end
function Logging.i3dInfo(node, infoMessage, ...)
    local nodeStr = I3DUtil.getNodeNameAndIndexPath(node)
    print(string.format("  Info (%s): " .. infoMessage, nodeStr, ...))
end
function Logging.xmlDevWarning(xmlFile, warningMessage, ...)
    -- upvalues: (copy) getFilename
    if g_showDevelopmentWarnings then
        local filename = getFilename(xmlFile)
        printWarning(string.format("  DevWarning (%s): " .. warningMessage, filename, ...))
    end
end
function Logging.xmlDevError(xmlFile, errorMessage, ...)
    -- upvalues: (copy) getFilename
    if g_showDevelopmentWarnings then
        local filename = getFilename(xmlFile)
        printError(string.format("  DevError (%s): " .. errorMessage, filename, ...))
    end
end
function Logging.xmlDevInfo(xmlFile, infoMessage, ...)
    -- upvalues: (copy) getFilename
    if g_showDevelopmentWarnings then
        local filename = getFilename(xmlFile)
        print(string.format("  DevInfo (%s): " .. infoMessage, filename, ...))
    end
end
function Logging.warning(warningMessage, ...)
    printWarning(string.format("  Warning: " .. warningMessage, ...))
end
function Logging.error(errorMessage, ...)
    printError(string.format("  Error: " .. errorMessage, ...))
end
function Logging.info(infoMessage, ...)
    print(string.format("  Info: " .. infoMessage, ...))
end
function Logging.fatal(fatalMessage, ...)
    local message = string.format("  Fatal Error: " .. fatalMessage, ...)
    printCallstack()
    requestExit()
    error(message)
end
function Logging.devWarning(warningMessage, ...)
    if g_showDevelopmentWarnings then
        printWarning(string.format("  DevWarning: " .. warningMessage, ...))
    end
end
function Logging.devError(errorMessage, ...)
    if g_showDevelopmentWarnings then
        printError(string.format("  DevError: " .. errorMessage, ...))
    end
end
function Logging.devInfo(infoMessage, ...)
    if g_showDevelopmentWarnings then
        print(string.format("  DevInfo: " .. infoMessage, ...))
    end
end