PlayerStyleConfig = {}
local PlayerStyleConfig_mt = Class(PlayerStyleConfig)
PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME = {
    ["hairStyle"] = ".hairStyles",
    ["glasses"] = ".glasses",
    ["headgear"] = ".headgear",
    ["facegear"] = ".facegear",
    ["face"] = ".faces",
    ["beard"] = ".beards",
    ["top"] = ".tops",
    ["gloves"] = ".gloves",
    ["bottom"] = ".bottoms",
    ["footwear"] = ".footwear",
    ["onepiece"] = ".onepieces"
}
function PlayerStyleConfig:ENABLED_GETTER_FILTER(_)
    return not self.playerStyle.disabledOptionsForSelection[self.name]
end
function PlayerStyleConfig.NOT_HIDDEN_GETTER_FILTER(_, _, gear)
    return not gear.hidden
end
function PlayerStyleConfig.NOT_FOR_HAT_GETTER_FILTER(_, _, hair)
    return not hair.forHat
end
function PlayerStyleConfig:SELECTED_GETTER_FILTER(index)
    return self.selectedItemIndex == index
end
function PlayerStyleConfig:NO_ONEPIECE_GETTER_FILTER(_)
    return self.playerStyle.configs.onepiece.selectedItemIndex == 0
end
function PlayerStyleConfig:BEARD_FACE_GETTER_FILTER(_, beard)
    return beard.faceName == nil or self.playerStyle.configs.face:getSelectedItem() ~= nil and beard.faceName == self.playerStyle.configs.face:getSelectedItem().name
end
function PlayerStyleConfig.registerXMLPaths(xmlSchema)
    for itemName, baseKeyName in pairs(PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME) do
        xmlSchema:register(XMLValueType.FILENAME, "player.playerStyle" .. baseKeyName .. "#nullIconFilename", "The icon filename to use when nothing is selected", nil, false)
        PlayerStyle.regsterIconGenerationXMLPaths(xmlSchema, "player.playerStyle" .. baseKeyName)
        PlayerStyleItem.registerXMLPaths(xmlSchema, "player.playerStyle" .. baseKeyName, itemName)
    end
end
function PlayerStyleConfig.registerSavegameXMLPaths(savegameXMLSchema, baseKey, configName)
    baseKey = baseKey .. "." .. configName
    savegameXMLSchema:register(XMLValueType.STRING, baseKey .. "#name", "The name of the config item", nil, false)
    savegameXMLSchema:register(XMLValueType.INT, baseKey .. "#color", "The name of the config item color", nil, false)
end
function PlayerStyleConfig.new(playerStyle, name, getterFilters, getterOr, resetSelectionToOne, isHair)
    -- upvalues: (copy) PlayerStyleConfig_mt
    local self = setmetatable({}, PlayerStyleConfig_mt)
    self.playerStyle = playerStyle
    self.name = name
    self.items = {}
    self.itemsByName = {}
    self.selectedItemIndex = 0
    self.selectedColorIndex = 1
    self.getterFilters = getterFilters or {}
    self.getterOr = getterOr == true
    self.resetSelectionToOne = resetSelectionToOne == true
    self.isHair = isHair == true
    return self
end
function PlayerStyleConfig:loadFromXMLNode(xmlFile, baseKey, defaultClothingColors, hairColors, attachmentPoints)
    local itemBaseKey = baseKey .. PlayerStyleConfig.CONFIG_BASE_KEY_NAMES_BY_NAME[self.name]
    for i, itemKey in xmlFile:iterator(itemBaseKey .. "." .. self.name) do
        local item = PlayerStyleItem.new()
        item:loadFromConfigurationXMLFile(xmlFile, itemKey, self.isHair and hairColors and hairColors or defaultClothingColors, attachmentPoints, self.isHair)
        self:addItem(item)
    end
    local nullIconFilename = xmlFile:getValue(itemBaseKey .. "#nullIconFilename", nil)
    if nullIconFilename ~= nil then
        local emptyItem = PlayerStyleItem.newEmpty(nullIconFilename)
        self.items[0] = emptyItem
        self.itemsByName[emptyItem.name] = emptyItem
    end
end
function PlayerStyleConfig:saveToSavegame(xmlFile, baseKey)
    baseKey = baseKey .. "." .. self.name
    xmlFile:setValue(baseKey .. "#color", self.selectedColorIndex)
    local selectedItem = self:getSelectedItem()
    if selectedItem == nil then
        xmlFile:removeProperty(baseKey .. "#name")
    else
        xmlFile:setValue(baseKey .. "#name", selectedItem.name)
    end
end
function PlayerStyleConfig:loadFromSavegame(xmlFile, baseKey)
    baseKey = baseKey .. "." .. self.name
    self.selectedColorIndex = xmlFile:getValue(baseKey .. "#color", 1)
    self.selectedItemIndex = 0
    local selectedItemName = xmlFile:getValue(baseKey .. "#name", nil)
    if not string.isNilOrWhitespace(selectedItemName) then
        self.selectedItemIndex = self:getItemNameIndex(selectedItemName)
        if self.selectedItemIndex == nil then
            Logging.xmlWarning(xmlFile, "Saved style item with name of %s could not be found!", selectedItemName)
            self.selectedItemIndex = self.resetSelectionToOne and 1 or 0
        end
    end
end
function PlayerStyleConfig:reset()
    table.clear(self.items)
    table.clear(self.itemsByName)
    self.selectedColorIndex = 1
    self.selectedItemIndex = self.resetSelectionToOne and 1 or 0
end
function PlayerStyleConfig:writeStream(streamId, _)
    streamWriteUInt8(streamId, self.selectedItemIndex)
    streamWriteUInt8(streamId, self.selectedColorIndex)
end
function PlayerStyleConfig:readStream(streamId, _)
    self.selectedItemIndex = streamReadUInt8(streamId)
    self.selectedColorIndex = streamReadUInt8(streamId)
end
function PlayerStyleConfig:addItem(item)
    table.insert(self.items, item)
    self.itemsByName[item.name] = item
end
function PlayerStyleConfig:copyConfigurationFrom(other)
    table.clear(self.items)
    table.clear(self.itemsByName)
    if other.items[0] ~= nil then
        self.items[0] = other.items[0]
        self.itemsByName[self.items[0].name] = self.items[0]
    end
    for _, item in ipairs(other.items) do
        self:addItem(item)
    end
end
function PlayerStyleConfig:copySelectionFrom(other)
    self.selectedItemIndex = other.selectedItemIndex
    self.selectedColorIndex = other.selectedColorIndex
end
function PlayerStyleConfig:getItemNameIndex(itemName)
    if string.isNilOrWhitespace(itemName) then
        return nil
    else
        local item = self.itemsByName[itemName]
        if item == nil then
            return nil
        else
            return self:getItemIndex(item)
        end
    end
end
function PlayerStyleConfig:getItemIndex(item)
    if item == nil then
        return nil
    else
        return item == self.items[0] and 0 or table.find(self.items, item)
    end
end
function PlayerStyleConfig:getSelectedItem()
    return self.items[self.selectedItemIndex]
end
function PlayerStyleConfig:setSelectedItem(item, forced)
    self:setSelectedItemIndex(self:getItemIndex(item), forced)
end
function PlayerStyleConfig:setSelectedItemName(name, forced)
    self:setSelectedItemIndex(self:getItemIndex(self.itemsByName[name]), forced)
end
function PlayerStyleConfig:setSelectedItemIndex(index, forced)
    if index == nil then
        return
    elseif self.selectedItemIndex ~= index or forced then
        local oldItem = self:getSelectedItem()
        self.selectedItemIndex = index
        if oldItem ~= nil and oldItem.hasDisabledItems then
            for configName in pairs(oldItem.disabledOptions) do
                if string.isNilOrWhitespace(configName) or self.playerStyle.configs[configName] == nil then
                    Logging.error("Item %s defines a disabled config %s, which does not correspond to any config!", oldItem.name, configName)
                elseif self.playerStyle.configs[configName].selectedItemIndex == 0 then
                    self.playerStyle.configs[configName]:setSelectedItemIndex(1)
                end
            end
            self.playerStyle:updateDisabledOptions()
        end
        local newItem = self:getSelectedItem()
        if newItem ~= nil then
            if newItem.colorableSlots > 0 and newItem.defaultPrimaryColorIndex ~= nil then
                self:setSelectedColorIndex(newItem.defaultPrimaryColorIndex)
            end
            if newItem.hasDisabledItems then
                for configName in pairs(newItem.disabledOptions) do
                    if string.isNilOrWhitespace(configName) or self.playerStyle.configs[configName] == nil then
                        Logging.error("Item %s defines a disabled config %s, which does not correspond to any config!", newItem.name, configName)
                    else
                        self.playerStyle.configs[configName]:setSelectedItemIndex(0)
                    end
                end
                self.playerStyle:updateDisabledOptions()
            end
        end
    end
end
function PlayerStyleConfig:getSelectedColorIndex()
    return self.selectedColorIndex
end
function PlayerStyleConfig:getSelectedColor()
    return self:getSelectedItem().possibleColors[self.selectedColorIndex]
end
function PlayerStyleConfig:setSelectedColorIndex(index)
    if index == nil then
        return
    elseif self.isHair then
        for _, config in pairs(self.playerStyle.configs) do
            if config.isHair then
                config.selectedColorIndex = index
            end
        end
    else
        self.selectedColorIndex = index
    end
end
function PlayerStyleConfig:getPossibleItemIndices()
    local possible = {}
    for index, item in ipairs(self.items) do
        if self:calculateGetterFiltersPassFor(index, item) then
            table.insert(possible, index)
        end
    end
    return possible
end
function PlayerStyleConfig:getPossibleItemsCount()
    local count = 0
    for index, item in ipairs(self.items) do
        if self:calculateGetterFiltersPassFor(index, item) then
        end
    end
    return count
end
function PlayerStyleConfig:calculateGetterFiltersPassFor(index, item)
    local includeItem = true
    if #self.getterFilters ~= 0 then
        includeItem = not self.getterOr
    end
    for _, filterFunction in ipairs(self.getterFilters) do
        local filterSucceeded = filterFunction(self, index, item)
        if self.getterOr and filterSucceeded then
            return true
        end
        if not (self.getterOr or filterSucceeded) then
            return false
        end
    end
    return includeItem
end
function PlayerStyleConfig:cloneAndEnableSelection(modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
    return self:cloneAndEnableItemIndex(self.selectedItemIndex, modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
end
function PlayerStyleConfig:cloneAndEnableItemIndex(index, modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
    local item = self.items[index]
    if item == nil or string.isNilOrWhitespace(item.filename) then
        Logging.warning("Index %d for config style item %q does not exist in %q!", index, self.name, self.playerStyle.xmlFilename)
        return nil, nil
    end
    local itemNode, itemNode2 = item:cloneAndEnable(modelParts, skeleton, i3dMappings, extentToCompare, extentToCompare2)
    if self.isHair then
        item:applyColorToHair(itemNode, itemNode2, self.selectedColorIndex)
        return itemNode, itemNode2
    end
    item:applyColorToNode(itemNode, self.selectedColorIndex)
    if itemNode2 ~= nil then
        item:applyColorToNode(itemNode2, self.selectedColorIndex)
    end
    return itemNode, itemNode2
end