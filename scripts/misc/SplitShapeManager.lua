SplitShapeManager = {}
local SplitShapeManager_mt = Class(SplitShapeManager, AbstractManager)
function SplitShapeManager.new(customMt)
    -- upvalues: (copy) SplitShapeManager_mt
    return AbstractManager.new(customMt or SplitShapeManager_mt)
end
function SplitShapeManager:initDataStructures()
    self.typesByIndex = {}
    self.typesByName = {}
    self.activeYarders = {}
end
function SplitShapeManager:loadMapData()
    SplitShapeManager:superClass().loadMapData(self)
    self:addSplitType("SPRUCE", "treeType_spruce", 1, 0.7, 3, true, nil, 1000, 6)
    self:addSplitType("PINE", "treeType_pine", 2, 0.7, 3, true, nil, 1000)
    self:addSplitType("LARCH", "treeType_larch", 3, 0.7, 3, true, nil, 1000)
    self:addSplitType("BIRCH", "treeType_birch", 4, 0.85, 3.2, true, nil, 1000)
    self:addSplitType("BEECH", "treeType_beech", 5, 0.9, 3.4, true, nil, 1000)
    self:addSplitType("MAPLE", "treeType_maple", 6, 0.9, 3.4, true, nil, 1000)
    self:addSplitType("OAK", "treeType_oak", 7, 0.9, 3.4, true, nil, 1000)
    self:addSplitType("ASH", "treeType_ash", 8, 0.9, 3.4, true, nil, 1000)
    self:addSplitType("LOCUST", "treeType_locust", 9, 1, 3.8, true, nil, 1000)
    self:addSplitType("MAHOGANY", "treeType_mahogany", 10, 1.1, 3, true, nil, 1000)
    self:addSplitType("POPLAR", "treeType_poplar", 11, 0.7, 7.5, true, nil, 1000)
    self:addSplitType("AMERICANELM", "treeType_americanElm", 12, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("CYPRESS", "treeType_cypress", 13, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("DOWNYSERVICEBERRY", "treeType_downyServiceberry", 14, 0.7, 3.5, false, nil, 1000)
    self:addSplitType("PAGODADOGWOOD", "treeType_pagodaDogwood", 15, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("SHAGBARKHICKORY", "treeType_shagbarkHickory", 16, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("STONEPINE", "treeType_stonePine", 17, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("WILLOW", "treeType_willow", 18, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("OLIVETREE", "treeType_oliveTree", 19, 0.6, 3.5, true, nil, 1000)
    self:addSplitType("GIANTSEQUOIA", "treeType_giantSequoia", 20, 0.3, 0.3, true, nil, 1000)
    self:addSplitType("LODGEPOLEPINE", "treeType_lodgepolePine", 21, 1, 3.7, true, nil, 1000)
    self:addSplitType("PONDEROSAPINE", "treeType_ponderosaPine", 22, 1, 3.7, true, nil, 1000)
    self:addSplitType("DEADWOOD", "treeType_deadwood", 23, 0.1, 0.5, true, nil, 1000)
    self:addSplitType("TRANSPORT", "treeType_transport", 24, 0.1, 0.3, true, nil, 10)
    self:addSplitType("ASPEN", "treeType_aspen", 25, 1.2, 3.3, true, nil, 1000)
    self:addSplitType("APPLE", "treeType_apple", 26, 0.8, 1.2, false, nil, 1000)
    self:addSplitType("BETULAERMANII", "treeType_betulaErmanii", 27, 0.6, 3.5, true, nil, 1000)
    self:addSplitType("BOXELDER", "treeType_boxelder", 28, 0.9, 3.4, true, nil, 1000)
    self:addSplitType("CHERRY", "treeType_cherry", 29, 1, 3.8, false, nil, 1000)
    self:addSplitType("CHINESEELM", "treeType_chineseElm", 30, 0.7, 3.5, false, nil, 1000)
    self:addSplitType("GOLDENRAIN", "treeType_goldenRain", 31, 0.6, 3.5, true, nil, 1000)
    self:addSplitType("JAPANESEZELKOVA", "treeType_japaneseZelkova", 32, 0.7, 3.5, true, nil, 1000)
    self:addSplitType("NORTHERNCATALPA", "treeType_northernCatalpa", 33, 0.7, 3, false, nil, 1000)
    self:addSplitType("TILIAAMURENSIS", "treeType_tiliaAmurensis", 34, 0.9, 3.4, false, nil, 1000)
    self:addSplitType("RAVAGED", "treeType_ravaged", 35, 0.4, 3, true, nil, 1000)
    self:addSplitType("PINUSTABULIFORMIS", "treeType_pinusTabuliformis", 36, 0.9, 3.5, true, nil, 1000)
    self:addSplitType("PINUSSYLVESTRIS", "treeType_pinusSylvestris", 37, 0.8, 3.3, true, nil, 1000)
    self:addSplitType("CHESTNUT", "treeType_chestnut", 38, 0.85, 3.3, true, nil, 1000)
    if g_isDevelopmentVersion then
        addConsoleCommand("gsSplitTypesExport", "Exports registered split types to xml files", "exportToXML", self)
    end
    return true
end
function SplitShapeManager:unloadMapData()
    removeConsoleCommand("gsSplitTypesExport")
    SplitShapeManager:superClass().unloadMapData(self)
end
function SplitShapeManager:addSplitType(name, l10nKey, splitTypeIndex, pricePerLiter, woodChipsPerLiter, allowsWoodHarvester, customEnvironment, volumeToLiter, woodHarvesterAreaThreshold)
    if self.typesByIndex[splitTypeIndex] == nil then
        local desc = string.upper(name)
        if self.typesByName[desc] == nil then
            if type(woodHarvesterAreaThreshold) ~= "number" then
                woodHarvesterAreaThreshold = nil
            end
            local desc = {
                ["name"] = desc,
                ["title"] = g_i18n:getText(l10nKey, customEnvironment),
                ["splitTypeIndex"] = splitTypeIndex,
                ["pricePerLiter"] = pricePerLiter,
                ["woodChipsPerLiter"] = woodChipsPerLiter,
                ["allowsWoodHarvester"] = allowsWoodHarvester,
                ["woodHarvesterAreaThreshold"] = woodHarvesterAreaThreshold or 4.5,
                ["volumeToLiter"] = volumeToLiter or 1000
            }
            self.typesByIndex[splitTypeIndex] = desc
            self.typesByName[desc] = desc
        else
            Logging.error("SplitShapeManager:addSplitType(): SplitType name \'%s\' is already in use", desc)
        end
    else
        Logging.error("SplitShapeManager:addSplitType(): SplitTypeIndex \'%d\' is already in use for \'%s\'", splitTypeIndex, name)
        return
    end
end
function SplitShapeManager:getSplitTypeByIndex(index)
    return self.typesByIndex[index]
end
function SplitShapeManager:getSplitTypeNameByIndex(index)
    local splitTypeData = self.typesByIndex[index]
    return splitTypeData == nil and "<NO_SPLIT_TYPE>" or splitTypeData.name
end
function SplitShapeManager:getSplitTypeIndexByName(name)
    if name == nil then
        return nil
    else
        local splitType = string.upper(name)
        local splitType = self.typesByName[splitType]
        if splitType == nil then
            return nil
        else
            return splitType.splitTypeIndex
        end
    end
end
function SplitShapeManager:getIsShapeCutAllowed(x, z, shape, farmId, connection)
    local isAllowed = g_missionManager:getIsShapeCutAllowed(shape, x, z, farmId)
    if isAllowed ~= nil then
        return isAllowed
    end
    if Platform.gameplay.treeCutFarmlandRestrictions and not g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) then
        return false
    end
    for objectId, _ in pairs(self.activeYarders) do
        local vehicle = NetworkUtil.getObject(objectId)
        if vehicle == nil then
            self.activeYarders[objectId] = nil
        elseif vehicle:getIsTreeShapeUsedForYarderSetup(shape) then
            return false
        end
    end
    return g_currentMission:getHasPlayerPermission("cutTrees", connection)
end
function SplitShapeManager:addActiveYarder(vehicle)
    local objectId = NetworkUtil.getObjectId(vehicle)
    self.activeYarders[objectId] = true
end
function SplitShapeManager:removeActiveYarder(vehicle)
    local objectId = NetworkUtil.getObjectId(vehicle)
    self.activeYarders[objectId] = nil
end
function SplitShapeManager.getSplitShapeAllowsHarvester(_, splitShapeId)
    local splitTypeIndex = getSplitType(splitShapeId)
    local splitTypeDesc = g_splitShapeManager:getSplitTypeByIndex(splitTypeIndex)
    if splitTypeDesc ~= nil and splitTypeDesc.allowsWoodHarvester then
        local _, sizeY, sizeZ, _, _ = getSplitShapeStats(splitShapeId)
        local area = sizeY * sizeZ
        if area > 0.01 and area < splitTypeDesc.woodHarvesterAreaThreshold then
            return true
        end
    end
    return false
end
function SplitShapeManager:exportToXML(_)
    if g_isDevelopmentVersion then
        local xmlFile = XMLFile.create("SplitTypes", "", "splitTypes")
        xmlFile:addComment("splitTypes", "Warning: This file is exported from script and should not be edited manually")
        local typesSorted = {}
        for _, desc in pairs(self.typesByName) do
            table.insert(typesSorted, desc)
        end
        table.sort(typesSorted, function(a, b)
            return a.splitTypeIndex < b.splitTypeIndex
        end)
        for _, desc in ipairs(typesSorted) do
            local element = string.format("splitTypes.splitType(%d)", _ - 1)
            xmlFile:setInt(element .. "#index", desc.splitTypeIndex)
            xmlFile:setString(element .. "#name", desc.name)
        end
        xmlFile:addComment("splitTypes", "Warning: This file is exported from script and should not be edited manually")
        xmlFile:saveTo("../tools/exporter/maya/splitTypes.xml", true)
        xmlFile:delete()
    end
end
g_splitShapeManager = SplitShapeManager.new()
g_splitTypeManager = {}
setmetatable(g_splitTypeManager, {
    ["__index"] = function(_, key)
        if FindDeletedObjects.isRunning == nil then
            Logging.error("\'g_splitTypeManager\' no longer exists, use \'g_splitShapeManager\' instead!")
            printCallstack()
        end
        return g_splitShapeManager[key]
    end
})