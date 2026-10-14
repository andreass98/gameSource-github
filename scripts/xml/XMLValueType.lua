XMLValueType = {}
XMLValueType.BASE_TYPES = {}
XMLValueType.TYPES = {}
function XMLValueType.getXMLStringList(xmlFile, path, _, numItems)
    local value = getXMLString(xmlFile, path)
    if value == nil then
        return nil
    end
    local parts = string.split(string.trim(value), " ")
    if numItems == nil or #parts == numItems then
        return parts
    end
    Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid string list in \'%s\'. Requires %d elements, %d found.", path, numItems, #parts)
    return nil
end
function XMLValueType.getXMLLocalization(xmlFile, path, default, customEnvironment, showWarning)
    local lastDot = path:findLast("%.")
    local firstPart = path:sub(0, lastDot - 1)
    local secondPart = path:sub(lastDot + 1, (string.len(path)))
    return XMLUtil.getXMLI18NValue(xmlFile, firstPart, getXMLString, secondPart, default, customEnvironment, showWarning)
end
function XMLValueType.getXMLFilename(xmlFile, path, default, baseDirectory)
    local value = getXMLString(xmlFile, path) or default
    if value == nil then
        return nil
    else
        return Utils.getFilename(value, baseDirectory)
    end
end
function XMLValueType.getXMLAngle(xmlFile, path, default)
    local value = getXMLFloat(xmlFile, path)
    if value ~= nil then
        return math.rad(value)
    end
    if default ~= nil then
        return math.rad(default)
    end
end
function XMLValueType.getXMLTime(xmlFile, path, default)
    local value = getXMLFloat(xmlFile, path)
    if value ~= nil then
        return value * 1000
    end
    if default ~= nil then
        return default * 1000
    end
end
function XMLValueType.getXMLDayTime(xmlFile, path, default)
    local valueStr = getXMLString(xmlFile, path) or default
    if valueStr == nil then
        return nil
    else
        local minutes = string.sub(valueStr, 1, 2)
        local hours = tonumber(minutes)
        local seconds = string.sub(valueStr, 4, 5)
        local minutes = tonumber(seconds)
        local millis = string.sub(valueStr, 7, 8)
        local seconds = tonumber(millis)
        local value = string.sub(valueStr, 10, 12)
        local millis = tonumber(value)
        if hours == nil or minutes == nil then
            return nil
        elseif hours < 0 or (hours > 23 or (minutes < 0 or minutes > 59)) then
            return nil
        else
            local seconds = seconds or 0
            local millis = millis or 0
            if seconds < 0 or (seconds > 59 or (millis < 0 or millis > 999)) then
                return nil
            else
                return millis + seconds * 1000 + minutes * 60 * 1000 + hours * 60 * 60 * 1000
            end
        end
    end
end
function XMLValueType.getXMLNode(xmlFile, path, default, components, i3dMappings)
    if components == nil then
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "No components given for \'%s\'.", path)
        printCallstack()
        return default
    end
    if type(default) == "string" then
        default = nil
    end
    local node, root = I3DUtil.indexToObject(components, getXMLString(xmlFile, path) or default, i3dMappings)
    return node or default, root
end
function XMLValueType.getXMLNodes(xmlFile, path, default, components, i3dMappings, packed)
    local defaultType = type(default)
    local defaultStr = nil
    local nodes
    if defaultType == "number" or defaultType == "nil" then
        nodes = { default }
    elseif defaultType == "string" then
        nodes = {}
        defaultStr = default
    else
        nodes = default
    end
    if components == nil then
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "No components given for \'%s\'.", path)
        printCallstack()
        if packed then
            return nodes
        else
            return unpack(nodes)
        end
    else
        local nodes = {}
        local nodesStr = getXMLString(xmlFile, path) or defaultStr
        if nodesStr ~= nil then
            local nodeParts = nodesStr:split(" ")
            local i = 1
            for i = i, #nodeParts do
                local node = I3DUtil.indexToObject(components, nodeParts[i], i3dMappings)
                if node == nil then
                    Logging.xmlWarning(xmlFile, "Unknown node \'%s\' in \'%s\'!", nodeParts[i], path)
                else
                    table.insert(nodes, node)
                end
            end
        end
        if #nodes == 0 then
            if packed then
                return nodes
            else
                return unpack(nodes)
            end
        elseif packed then
            return nodes
        else
            return unpack(nodes)
        end
    end
end
function XMLValueType.getVectorFromXML(xmlFile, path, default)
    local valueStr = getXMLString(xmlFile, path)
    if valueStr ~= nil then
        local result = string.getVector(valueStr)
        if result ~= nil then
            return result
        end
    end
    if default == nil then
        return nil
    end
    if type(default) == "string" then
        return string.getVector(default)
    end
    if type(default) == "table" then
        return default
    end
    Logging.warning("Default value is neither a table nor a string")
    printCallstack()
    return nil
end
function XMLValueType.getXMLVector2(xmlFile, path, default, packed)
    local vector = XMLValueType.getVectorFromXML(xmlFile, path, default)
    if vector == nil then
        return nil
    elseif #vector == 2 then
        if packed then
            return vector
        else
            return unpack(vector)
        end
    else
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 2 for \'%s\'.", path)
        return nil
    end
end
function XMLValueType.getXMLVector3(xmlFile, path, default, packed)
    local vector = XMLValueType.getVectorFromXML(xmlFile, path, default)
    if vector == nil then
        return nil
    elseif #vector == 3 then
        if packed then
            return vector
        else
            return unpack(vector)
        end
    else
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 3 for \'%s\'.", path)
        return nil
    end
end
function XMLValueType.getXMLVector4(xmlFile, path, default, packed)
    local vector = XMLValueType.getVectorFromXML(xmlFile, path, default)
    if vector == nil then
        return nil
    elseif #vector == 4 then
        if packed then
            return vector
        else
            return unpack(vector)
        end
    else
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 4 for \'%s\'.", path)
        return nil
    end
end
function XMLValueType.getXMLVectorN(xmlFile, path, default, packed)
    if packed then
        return XMLValueType.getVectorFromXML(xmlFile, path, default)
    end
    return unpack(XMLValueType.getVectorFromXML(xmlFile, path, default))
end
function XMLValueType.getXMLVector3Angle(xmlFile, path, default, packed)
    if type(default) == "table" then
        local i = 1
        for i = i, #default do
            default[i] = math.deg(default[i])
        end
    end
    local vector = XMLValueType.getVectorFromXML(xmlFile, path, default)
    if vector ~= nil then
        if #vector == 3 then
            if not packed then
                return math.rad(vector[1]), math.rad(vector[2]), math.rad(vector[3])
            end
            local i = vector[1]
            local v9_ = math.rad(i)
            local i = math.rad(vector[2])
            vector[1] = v9_
            vector[2] = i
            vector[3] = math.rad(vector[3])
            return vector
        end
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 3 for \'%s\'.", path)
    end
    return nil
end
function XMLValueType.getXMLVector2Angle(xmlFile, path, default, packed)
    if type(default) == "table" then
        local i = 1
        for i = i, #default do
            default[i] = math.deg(default[i])
        end
    end
    local vector = XMLValueType.getVectorFromXML(xmlFile, path, default)
    if vector ~= nil then
        if #vector == 2 then
            if not packed then
                return math.rad(vector[1]), math.rad(vector[2])
            end
            local i = vector[1]
            local v17_ = math.rad(i)
            local i = math.rad(vector[2])
            vector[1] = v17_
            vector[2] = i
            return vector
        end
        Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 2 for \'%s\'.", path)
    end
    return nil
end
function XMLValueType.getXMLColor(xmlFile, path, default, packed, customEnvironment)
    local colorStr = getXMLString(xmlFile, path)
    if colorStr == nil then
        if type(default) ~= "string" then
            return default
        end
        colorStr = default
    end
    local color = g_vehicleMaterialManager:getMaterialTemplateColorByName(colorStr, customEnvironment)
    if color == nil then
        local color = string.split(colorStr, " ", tonumber)
        if #color == 3 then
            default = color
        else
            if colorStr ~= nil then
                Logging.xmlWarning(xmlFile, "Invalid color value \'%s\' in \'%s\'.", colorStr, path)
            end
            if type(default) == "string" then
                default = string.getVector(default)
                if #default ~= 3 then
                    return nil
                end
            elseif default == nil then
                return nil
            end
        end
    else
        default = color
    end
    if packed then
        return default
    else
        return unpack(default)
    end
end
function XMLValueType.getXMLVehicleMaterial(xmlFile, path, default, customEnvironment)
    local colorStr = getXMLString(xmlFile, path)
    if colorStr == nil then
        return default
    else
        local material = VehicleMaterial.new()
        if g_vehicleMaterialManager:getMaterialTemplateByName(colorStr, customEnvironment) == nil then
            local color = string.split(colorStr, " ", tonumber)
            if #color >= 3 then
                material.colorScale = { color[1], color[2], color[3] }
                return material
            else
                Logging.xmlWarning(xmlFile, "Invalid vehicle material template \'%s\' in \'%s\'.", colorStr, path)
                return default
            end
        else
            material:setTemplateName(colorStr, nil, customEnvironment)
            return material
        end
    end
end
function XMLValueType.setXMLStringList(xmlFile, path, ...)
    local str = ""
    local i = 1
    for i = i, select("#", ...) do
        if i > 1 then
        end
        str = str .. select(i, ...)
    end
    setXMLString(xmlFile, path, str)
end
function XMLValueType.setXMLAngle(xmlFile, path, value)
    setXMLFloat(xmlFile, path, (math.deg(value or 0)))
end
function XMLValueType.setXMLTime(xmlFile, path, value)
    setXMLFloat(xmlFile, path, (value or 0) / 1000)
end
function XMLValueType.setXMLDayTime(xmlFile, path, value)
    local str = string.format("%02d:%02d:%02d.%03d", value / 3600000 % 24, value / 60000 % 60, value / 1000 % 60, value % 1000)
    setXMLString(xmlFile, path, str)
end
function XMLValueType.setXMLNode(xmlFile, path, value)
    if entityExists(value) then
        setXMLString(xmlFile, path, getName(value))
    end
end
function XMLValueType.setXMLNodes(xmlFile, path, ...)
    local str = ""
    for i, node in ipairs({ ... }) do
        if i > 1 then
        end
        if entityExists(node) then
            str = str + getName(node)
        end
    end
    setXMLString(xmlFile, path, str)
end
function XMLValueType.setXMLVector2(xmlFile, path, val1, val2)
    setXMLString(xmlFile, path, string.format("%s %s", val1, val2))
end
function XMLValueType.setXMLVector3(xmlFile, path, val1, val2, val3)
    setXMLString(xmlFile, path, string.format("%s %s %s", val1, val2, val3))
end
function XMLValueType.setXMLVector4(xmlFile, path, val1, val2, val3, val4)
    setXMLString(xmlFile, path, string.format("%s %s %s %s", val1, val2, val3, val4))
end
function XMLValueType.setXMLVectorN(xmlFile, path, ...)
    setXMLString(xmlFile, path, table.concat({ ... }, " "))
end
function XMLValueType.setXMLVectorTrans(xmlFile, path, x, y, z)
    setXMLString(xmlFile, path, string.format("%.3f %.3f %.3f", x, y, z))
end
function XMLValueType.setXMLVector3Angle(xmlFile, path, rx, ry, rz)
    setXMLString(xmlFile, path, string.format("%.2f %.2f %.2f", math.deg(rx), math.deg(ry), (math.deg(rz))))
end
function XMLValueType.setXMLVector2Angle(xmlFile, path, r1, r2)
    setXMLString(xmlFile, path, string.format("%.2f %.2f", math.deg(r1), (math.deg(r2))))
end
function XMLValueType.setXMLColor(xmlFile, path, ...)
    setXMLString(xmlFile, path, table.concat({ ... }, " "))
end
function XMLValueType.setXMLVehicleMaterial(xmlFile, path, r, g, b)
    if type(r) == "string" then
        setXMLString(xmlFile, path, r)
    else
        setXMLString(xmlFile, path, string.format("%s %s %s", r, g, b))
    end
end
function XMLValueType.registerBaseType(name, content)
    XMLValueType.BASE_TYPES[#XMLValueType.BASE_TYPES + 1] = {
        ["name"] = name,
        ["content"] = content
    }
end
XMLValueType.registerBaseType("VECTOR_FLOAT", "<xs:list itemType=\"xs:float\"/>")
function XMLValueType.register(name, description, get, set, isBasicFunction, luaType, defaultStr, xsdBase, xsdPattern, luaPattern)
    XMLValueType.TYPES[#XMLValueType.TYPES + 1] = {
        ["name"] = name,
        ["description"] = description,
        ["get"] = get,
        ["set"] = set,
        ["isBasicFunction"] = isBasicFunction,
        ["luaType"] = luaType,
        ["defaultStr"] = defaultStr,
        ["xsdBase"] = xsdBase,
        ["xsdPattern"] = xsdPattern,
        ["luaPattern"] = luaPattern
    }
    XMLValueType[string.upper(name)] = #XMLValueType.TYPES
    return #XMLValueType.TYPES
end
XMLValueType.STRING = XMLValueType.register("STRING", "String", getXMLString, setXMLString, true, "string", "string", "xs:string")
XMLValueType.STRING_LIST = XMLValueType.register("STRING_LIST", "One or more strings separated by a single whitespace", XMLValueType.getXMLStringList, XMLValueType.setXMLStringList, true, "string", "str1 str2 ..", "xs:string", "\\S+( \\S+)*")
XMLValueType.L10N_STRING = XMLValueType.register("L10N_STRING", "String or l10n key", XMLValueType.getXMLLocalization, setXMLString, false, "string", "string", "xs:string")
XMLValueType.FILENAME = XMLValueType.register("FILENAME", "Path to a certain file", XMLValueType.getXMLFilename, setXMLString, false, "string", "string", "xs:string")
XMLValueType.FLOAT = XMLValueType.register("FLOAT", "Float", getXMLFloat, setXMLFloat, true, "number", "float", "xs:float")
XMLValueType.ANGLE = XMLValueType.register("ANGLE", "Angle", XMLValueType.getXMLAngle, XMLValueType.setXMLAngle, false, "number", "angle", "xs:float")
XMLValueType.TIME = XMLValueType.register("TIME", "Time in seconds", XMLValueType.getXMLTime, XMLValueType.setXMLTime, false, "number", "time", "xs:float")
XMLValueType.DAY_TIME = XMLValueType.register("DAY_TIME", "Time hh:mm:ss.sss format", XMLValueType.getXMLDayTime, XMLValueType.setXMLDayTime, false, "string", "hh:mm:ss", "xs:time")
XMLValueType.INT = XMLValueType.register("INT", "Integer", getXMLInt, setXMLInt, true, "number", "integer", "xs:integer")
XMLValueType.UINT = XMLValueType.register("UINT", "Integer (unsigned)", getXMLUInt, setXMLUInt, true, "number", "integer", "xs:integer")
XMLValueType.BOOL = XMLValueType.register("BOOL", "Boolean", getXMLBool, setXMLBool, true, "boolean", "boolean", "xs:string", "true|false", { true, false })
XMLValueType.NODE_INDEX = XMLValueType.register("NODE_INDEX", "Index to i3d node or i3d mapping identifier", XMLValueType.getXMLNode, XMLValueType.setXMLNode, false, "string", "node", "xs:string", nil, {})
XMLValueType.NODE_INDICES = XMLValueType.register("NODE_INDICES", "List of indices to i3d nodes or i3d mapping identifiers", XMLValueType.getXMLNodes, XMLValueType.setXMLNodes, false, "string", "node", "xs:string", nil, {})
XMLValueType.VECTOR_2 = XMLValueType.register("VECTOR_2", "Multiple values (x, y)", XMLValueType.getXMLVector2, XMLValueType.setXMLVector2, false, "string", "x y", "g_vector_float", "\\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_3 = XMLValueType.register("VECTOR_3", "Multiple values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_4 = XMLValueType.register("VECTOR_4", "Multiple values (x, y, z, w)", XMLValueType.getXMLVector4, XMLValueType.setXMLVector4, false, "string", "x y z w", "g_vector_float", "\\S+ \\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_N = XMLValueType.register("VECTOR_N", "Multiple values", XMLValueType.getXMLVectorN, XMLValueType.setXMLVectorN, false, "string", "1 2 .. n", "g_vector_float")
XMLValueType.VECTOR_TRANS = XMLValueType.register("VECTOR_TRANS", "Translation values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVectorTrans, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_ROT = XMLValueType.register("VECTOR_ROT", "Rotation values (x, y, z)", XMLValueType.getXMLVector3Angle, XMLValueType.setXMLVector3Angle, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_ROT_2 = XMLValueType.register("VECTOR_ROT_2", "Rotation values (x, y)", XMLValueType.getXMLVector2Angle, XMLValueType.setXMLVector2Angle, false, "string", "x y", "g_vector_float", "\\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_SCALE = XMLValueType.register("VECTOR_SCALE", "Scale values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%d*%.?%d+%s%d*%.?%d+%s%d*%.?%d+)")
XMLValueType.COLOR = XMLValueType.register("COLOR", "Color values (r, g, b) or brand color id", XMLValueType.getXMLColor, XMLValueType.setXMLColor, false, "string", "r g b", "xs:string")
XMLValueType.VEHICLE_MATERIAL = XMLValueType.register("VEHICLE_MATERIAL", "Name of brand material template or color values (r,g,b)", XMLValueType.getXMLVehicleMaterial, XMLValueType.setXMLVehicleMaterial, false, "string", "string", "xs:string")