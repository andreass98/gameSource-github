InfoLayer = {}
local InfoLayer_mt = Class(InfoLayer)
function InfoLayer.new(name, baseDirectory, customMt)
    -- upvalues: (copy) InfoLayer_mt
    local self = setmetatable({}, customMt or InfoLayer_mt)
    self.baseDirectory = baseDirectory
    self.bitVector = createBitVectorMap(name)
    self.name = name
    self.width = 0
    self.height = 0
    self.doDelete = true
    return self
end
function InfoLayer.newFromMap(terrainNode, name, customMt)
    -- upvalues: (copy) InfoLayer_mt
    local self = setmetatable({}, customMt or InfoLayer_mt)
    self.name = name
    local infoLayerId = getInfoLayerFromTerrain(terrainNode, name)
    if infoLayerId == nil or infoLayerId == 0 then
        Logging.warning("Missing infolayer \'%s\' in map", name)
        return nil
    end
    if self:loadFromMemory(infoLayerId) then
        return self
    end
    Logging.warning("Could not load infolayer from map")
    return nil
end
function InfoLayer:loadFromXML(xmlFile, key)
    return self:load(Utils.getFilename(xmlFile:getString(key .. "#filename"), self.baseDirectory), (xmlFile:getInt(key .. "#numChannels")))
end
function InfoLayer:load(filename, numChannels)
    if not loadBitVectorMapFromFile(self.bitVector, filename, numChannels) then
        printWarning("Warning: Loading infolayer \'" .. self.name .. "\' file \'" .. tostring(filename) .. "\' failed!")
        return false
    end
    self.numChannels = numChannels
    self.width, self.height = getBitVectorMapSize(self.bitVector)
    return true
end
function InfoLayer:create(width, height, numChannels, initAll)
    loadBitVectorMapNew(self.bitVector, width, height, numChannels, initAll)
    self.numChannels = numChannels
    self.width = width
    self.height = height
    return true
end
function InfoLayer:loadFromMemory(id)
    self.doDelete = false
    self.bitVector = id
    self.numChannels = getBitVectorMapNumChannels(id)
    self.width, self.height = getBitVectorMapSize(id)
    return true
end
function InfoLayer:delete()
    if self.doDelete then
        delete(self.bitVector)
    end
end
function InfoLayer:writeStream(streamId, _)
    writeBitVectorMapToStream(self.bitVector, streamId)
end
function InfoLayer:readStream(streamId, _)
    readBitVectorMapFromStream(self.bitVector, streamId)
end
function InfoLayer:getId()
    return self.bitVector
end
function InfoLayer:convertWorldToLocalPosition(worldPosX, worldPosZ)
    local terrainSize = g_currentMission.terrainSize
    return math.floor(self.width * (worldPosX + terrainSize * 0.5) / terrainSize), math.floor(self.height * (worldPosZ + terrainSize * 0.5) / terrainSize)
end
function InfoLayer:getValueAtWorldPos(worldX, worldZ, firstChannel, numChannels)
    local x, y = self:convertWorldToLocalPosition(worldX, worldZ)
    return getBitVectorMapPoint(self.bitVector, x, y, firstChannel or 0, numChannels or self.numChannels)
end
function InfoLayer:getValueAtPos(x, y, firstChannel, numChannels)
    return getBitVectorMapPoint(self.bitVector, x, y, firstChannel or 0, numChannels or self.numChannels)
end
function InfoLayer:getValueAtParallelogram(x, y, widthX, widthY, heightX, heightY, firstChannel, numChannels, roundingMode)
    return getBitVectorMapParallelogram(self.bitVector, x, y, widthX - x, widthY - y, heightX - x, heightY - y, firstChannel or 0, numChannels or self.numChannels, roundingMode)
end
function InfoLayer:getValueAtWorldParallelogram(worldX, worldZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ, firstChannel, numChannels, roundingMode)
    local x, y = self:convertWorldToLocalPosition(worldX, worldZ)
    local widthX, widthY = self:convertWorldToLocalPosition(worldWidthX, worldWidthZ)
    local heightX, heightY = self:convertWorldToLocalPosition(worldHeightX, worldHeightZ)
    return getBitVectorMapParallelogram(self.bitVector, x, y, widthX - x, widthY - y, heightX - x, heightY - y, firstChannel or 0, numChannels or self.numChannels, roundingMode)
end
function InfoLayer:setValueAtWorldParallelogram(worldX, worldZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ, firstChannel, numChannels, value, roundingMode)
    local x, y = self:convertWorldToLocalPosition(worldX, worldZ)
    local widthX, widthY = self:convertWorldToLocalPosition(worldWidthX, worldWidthZ)
    local heightX, heightY = self:convertWorldToLocalPosition(worldHeightX, worldHeightZ)
    setBitVectorMapParallelogram(self.bitVector, x, y, widthX - x, widthY - y, heightX - x, heightY - y, firstChannel or 0, numChannels or self.numChannels, value, roundingMode)
end
function InfoLayer:setValueAtArea(area, value)
    if self.modifier == nil then
        self.modifier = DensityMapModifier.new(self.bitVector, 0, self.numChannels, g_terrainNode)
    end
    area:applyToModifier(self.modifier)
    self.modifier:executeSet(value)
end
function InfoLayer:saveToFile(filename, asyncCallback, asyncTarget)
    if asyncCallback == nil then
        saveBitVectorMapToFile(self.bitVector, filename)
    else
        prepareSaveBitVectorMapToFile(self.bitVector, filename)
        savePreparedBitVectorMapToFile(self.bitVector, asyncCallback, asyncTarget)
    end
end