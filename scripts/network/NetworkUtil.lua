NetworkUtil = {}
function NetworkUtil.getObject(id)
    if g_server == nil then
        return g_client:getObject(id)
    else
        return g_server:getObject(id)
    end
end
function NetworkUtil.getObjectId(object)
    if g_server == nil then
        return g_client:getObjectId(object)
    else
        return g_server:getObjectId(object)
    end
end
function NetworkUtil.writeNodeObject(streamId, object)
    if g_showDevelopmentWarnings then
        if object == nil then
            Logging.devError("Trying to write nil object")
            printCallstack()
        elseif not object.isRegistered then
            Logging.devError("Trying to write unregistered object")
            printCallstack()
        end
    end
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(object))
end
function NetworkUtil.readNodeObject(streamId)
    return NetworkUtil.getObject(NetworkUtil.readNodeObjectId(streamId))
end
function NetworkUtil.writeNodeObjectId(streamId, objectId)
    streamWriteUIntN(streamId, objectId or 0, NetworkNode.OBJECT_SEND_NUM_BITS)
end
function NetworkUtil.readNodeObjectId(streamId)
    return streamReadUIntN(streamId, NetworkNode.OBJECT_SEND_NUM_BITS)
end
function NetworkUtil.createWorldPositionCompressionParams(worldSize, worldOffset, scale)
    return {
        ["scale"] = scale,
        ["worldSize"] = worldSize,
        ["worldOffset"] = worldOffset,
        ["numBits"] = MathUtil.getNumRequiredBits(worldSize / scale)
    }
end
function NetworkUtil.simWriteCompressedWorldPosition(pos, params)
    local scaledPos = math.clamp(pos + params.worldOffset, 0, params.worldSize) / params.scale
    return math.floor(scaledPos) * params.scale - params.worldOffset
end
function NetworkUtil.writeCompressedWorldPosition(streamId, pos, params)
    local scaledPos = math.clamp(pos + params.worldOffset, 0, params.worldSize) / params.scale
    streamWriteUIntN(streamId, math.floor(scaledPos), params.numBits)
end
function NetworkUtil.getIsWorldPositionInCompressionRange(pos, params)
    return -params.worldOffset <= pos and pos <= params.worldSize - params.worldOffset
end
function NetworkUtil.readCompressedWorldPosition(streamId, params)
    return streamReadUIntN(streamId, params.numBits) * params.scale - params.worldOffset
end
function NetworkUtil.writeCompressedAngle(streamId, angle)
    streamWriteUIntN(streamId, math.floor(angle % 6.283185307179586 * 2047.5 / 3.141592653589793), 12)
end
function NetworkUtil.readCompressedAngle(streamId)
    return streamReadUIntN(streamId, 12) / 2047.5 * 3.141592653589793
end
function NetworkUtil.writeCompressedRange(streamId, value, minValue, maxValue, numBits)
    value = minValue == maxValue and 0 or (math.clamp(value, minValue, maxValue) - minValue) / (maxValue - minValue)
    streamWriteUIntN(streamId, math.floor(value * (2 ^ numBits - 1)), numBits)
end
function NetworkUtil.readCompressedRange(streamId, minValue, maxValue, numBits)
    return streamReadUIntN(streamId, numBits) / (2 ^ numBits - 1) * (maxValue - minValue) + minValue
end
function NetworkUtil.writeCompressedPercentages(streamId, floatValue, numBits)
    numBits = numBits or 7
    local maxBitValue = 2 ^ numBits - 1
    local value = math.clamp(floatValue * maxBitValue, 0, maxBitValue)
    streamWriteUIntN(streamId, value, numBits)
end
function NetworkUtil.readCompressedPercentages(streamId, numBits)
    numBits = numBits or 7
    return streamReadUIntN(streamId, numBits) / (2 ^ numBits - 1)
end
function NetworkUtil.convertToNetworkFilename(filename)
    local modFilename, isMod, isDlc, _ = Utils.removeModDirectory(string.trim(filename))
    if isMod then
        return "$moddir$" .. modFilename
    end
    if isDlc then
        filename = "$pdlcdir$" .. modFilename
    end
    return filename
end
function NetworkUtil.convertFromNetworkFilename(filename)
    local filenameLower = string.lower(filename)
    if string.startsWith(filenameLower, "$moddir$") then
        local startIndex = 9
        local f, l = string.find(filename, "/", 9)
        local modDir
        if f == nil or (l == nil or startIndex >= f - 1) then
            modDir = filename
        else
            modDir = string.sub(filename, startIndex, f - 1)
        end
        local modDir = g_modNameToDirectory[modDir]
        if modDir == nil then
            return g_modsDirectory .. modDir
        end
        return modDir .. string.sub(filename, f + 1)
    elseif string.startsWith(filenameLower, "$mapdir$") then
        return Utils.getFilename(string.sub(filename, 10), g_currentMission.missionInfo.baseDirectory)
    else
        if string.startsWith(filenameLower, "$pdlcdir") then
            local modName = nil
            local f = 9
            if string.sub(filenameLower, f, f) == "$" then
                modName = f + 1
            else
                local f = f + 1
                if string.sub(filenameLower, f, f) == "$" then
                    modName = f + 1
                end
            end
            if modName ~= nil then
                local l, modDir = string.find(filename, "/", modName)
                if l ~= nil and (modDir ~= nil and modName < l - 1) then
                    local modName = string.sub(filename, modName, l - 1)
                    if g_dlcModNameHasPrefix[modName] then
                    end
                    local modDir = g_modNameToDirectory[modName]
                    if modDir ~= nil then
                        filename = modDir .. string.sub(filename, l + 1)
                    end
                end
            end
        end
        return filename
    end
end
function NetworkUtil.packBits(...)
    local args = { ... }
    local result = 0
    local i = 1
    for i = i, #args do
        if args[i] then
        end
    end
    return result
end
function NetworkUtil.readBits(number, arity)
    if arity == nil then
        if number == 0 then
            return
        end
        local arity = number >= 0
        assert(arity)
        local n = 1
        local arity = 1
        while n <= number do
            n = 2 * n
        end
        arity = arity - 1
    end
    local number = {}
    local n = 1
    local arity = -1
    for arity = arity, n, arity do
        local value = 2 ^ (arity - 1)
        local isBitSet = value <= number
        number[arity] = isBitSet
        if isBitSet then
        end
    end
    return number
end
function NetworkUtil.readBit(number, bitPosition, arity)
    if arity == nil then
        if number == 0 then
            return
        end
        local arity = number >= 0
        assert(arity)
        local n = 1
        local arity = 1
        while n <= number do
            n = 2 * n
        end
        arity = arity - 1
    end
    local arity = arity - 1
    local number = bitPosition + 1
    local n = -1
    for arity = arity, number, n do
        local value = 2 ^ arity
        if value <= number then
        end
    end
    local n = 2 ^ bitPosition <= number
    return n
end
function NetworkUtil.writeBit(number, bitPosition, bitValue, arity)
    if arity == nil then
        if number == 0 then
            return
        end
        local arity = number >= 0
        assert(arity)
        local n = 1
        local arity = 1
        while n <= number do
            n = 2 * n
        end
        arity = arity - 1
    end
    local number = NetworkUtil.readBit(number, bitPosition, arity)
    local n = 2 ^ bitPosition
    if number then
    end
    if bitValue then
    end
    return number
end
function NetworkUtil.writeCompressedColor(streamId, r, g, b)
    streamWriteUInt8(streamId, r * 255)
    streamWriteUInt8(streamId, g * 255)
    streamWriteUInt8(streamId, b * 255)
end
function NetworkUtil.readCompressedColor(streamId)
    return streamReadUInt8(streamId) / 255, streamReadUInt8(streamId) / 255, streamReadUInt8(streamId) / 255
end