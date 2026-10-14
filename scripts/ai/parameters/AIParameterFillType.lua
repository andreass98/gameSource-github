AIParameterFillType = {}
local AIParameterFillType_mt = Class(AIParameterFillType, AIParameter)
function AIParameterFillType.new(customMt)
    -- upvalues: (copy) AIParameterFillType_mt
    local self = AIParameter.new(customMt or AIParameterFillType_mt)
    self.type = AIParameterType.FILLTYPE
    self.fillTypes = {}
    self.fillTypeIndex = nil
    return self
end
function AIParameterFillType:saveToXMLFile(xmlFile, key, _)
    if self.fillTypeIndex ~= nil then
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(self.fillTypeIndex)
        xmlFile:setString(key .. "#fillType", fillTypeName)
    end
end
function AIParameterFillType:loadFromXMLFile(xmlFile, key)
    local fillTypeName = xmlFile:getString(key .. "#fillType")
    if fillTypeName ~= nil then
        self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
    end
end
function AIParameterFillType:readStream(streamId, _)
    if streamReadBool(streamId) then
        self:setFillTypeIndex((streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
    end
end
function AIParameterFillType:writeStream(streamId, _)
    if streamWriteBool(streamId, self.fillTypeIndex ~= nil) then
        streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
    end
end
function AIParameterFillType:setValidFillTypes(fillTypes)
    self.fillTypes = {}
    local maxFillLevelFillTypeIndex = nil
    local isCurrentFillTypeIndexAvailable = false
    for fillTypeIndex, fillLevel in pairs(fillTypes) do
        if 0 < fillLevel then
            maxFillLevelFillTypeIndex = fillTypeIndex
        end
        local title = g_fillTypeManager:getFillTypeTitleByIndex(fillTypeIndex)
        local title = string.format("%s (%d l)", title, fillLevel)
        table.insert(self.fillTypes, {
            ["index"] = #self.fillTypes + 1,
            ["fillTypeIndex"] = fillTypeIndex,
            ["title"] = title,
            ["fillLevel"] = fillLevel
        })
    end
    table.sort(self.fillTypes, function(a, b)
        return a.title < b.title
    end)
    if self.fillTypeIndex == nil or not isCurrentFillTypeIndexAvailable then
        if maxFillLevelFillTypeIndex ~= nil then
            self.fillTypeIndex = maxFillLevelFillTypeIndex
            return
        end
        self:setFillTypeByIndex(1)
    end
end
function AIParameterFillType:setNextItem()
    local nextIndex = 0
    for k, data in ipairs(self.fillTypes) do
        if self.fillTypeIndex == data.fillTypeIndex then
            nextIndex = k + 1
        end
    end
    self:setFillTypeByIndex(#self.fillTypes < nextIndex and 1 or nextIndex)
end
function AIParameterFillType:setPreviousItem()
    local previousIndex = 0
    for k, data in ipairs(self.fillTypes) do
        if self.fillTypeIndex == data.fillTypeIndex then
            previousIndex = k - 1
        end
    end
    self:setFillTypeByIndex(previousIndex < 1 and #self.fillTypes or previousIndex)
end
function AIParameterFillType:setFillTypeByIndex(index)
    local data = self.fillTypes[index]
    if data == nil then
        self.fillTypeIndex = nil
    else
        self.fillTypeIndex = data.fillTypeIndex
    end
end
function AIParameterFillType:setFillTypeIndex(fillTypeIndex)
    self.fillTypeIndex = fillTypeIndex
end
function AIParameterFillType:getFillTypeIndex()
    return self.fillTypeIndex
end
function AIParameterFillType:getString()
    for _, data in ipairs(self.fillTypes) do
        if data.fillTypeIndex == self.fillTypeIndex then
            return data.title
        end
    end
    return ""
end
function AIParameterFillType:validate()
    if self.fillTypeIndex == nil then
        return false, g_i18n:getText("ai_validationErrorNoFillType")
    else
        return true, nil
    end
end