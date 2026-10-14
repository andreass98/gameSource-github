ValueMap = {}
ValueMap.MOD_NAME = g_currentModName
local ValueMap_mt = Class(ValueMap)
function ValueMap.new(pfModule, customMt)
    -- upvalues: (copy) ValueMap_mt
    local self = setmetatable({}, customMt or ValueMap_mt)
    self.pfModule = pfModule
    self.filename = "valueMap.grle"
    self.name = "valueMap"
    self.id = "VALUE_MAP"
    self.label = "unknown"
    self.requireMinimapDisplay = false
    self.minimapSourceObject = nil
    self.minimapSourceObjectSelected = false
    self.requireMinimapUpdate = false
    self.minimapMissionState = false
    self.minimapAdditionalElementRealSize = { -1, -1 }
    self.minimapAdditionalElementLinkNode = nil
    self.minimapGradientSliceId = nil
    self.minimapGradientColorBlindSliceId = nil
    self.minimapLabelName = nil
    self.minimapLabelNameMission = nil
    self.minimapGradientLabelName = nil
    self.bitVectorMapsToSync = {}
    self.bitVectorMapsToSave = {}
    self.bitVectorMapsToDelete = {}
    return self
end
function ValueMap:initialize()
    self.bitVectorMapsToSync = {}
    self.bitVectorMapsToSave = {}
    self.bitVectorMapsToDelete = {}
    self.requireMinimapDisplay = false
    self.minimapSourceObject = nil
    self.minimapSourceObjectSelected = false
    self.requireMinimapUpdate = false
    self.minimapMissionState = false
end
function ValueMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return true
end
function ValueMap:postLoad(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return true
end
function ValueMap.loadSavedBitVectorMap(_, name, filename, numChannels, size)
    local missionInfo = g_currentMission.missionInfo
    local savegameFilename = nil
    if missionInfo.savegameDirectory ~= nil then
        savegameFilename = missionInfo.savegameDirectory .. "/" .. filename
        if not fileExists(savegameFilename) then
            savegameFilename = nil
        end
    end
    local bitVectorMap = createBitVectorMap(name)
    if savegameFilename ~= nil and not loadBitVectorMapFromFile(bitVectorMap, savegameFilename, numChannels) then
        Logging.error("while loading bit vector map \'%s\'", savegameFilename)
    end
    local newValueMap = false
    if savegameFilename == nil then
        delete(bitVectorMap)
        bitVectorMap = createBitVectorMap(name)
        loadBitVectorMapNew(bitVectorMap, size, size, numChannels, false)
        newValueMap = true
    end
    return bitVectorMap, newValueMap
end
function ValueMap:addBitVectorMapToSync(bitVectorMap)
    if bitVectorMap ~= nil then
        table.insert(self.bitVectorMapsToSync, {
            ["bitVectorMap"] = bitVectorMap
        })
    end
end
function ValueMap:addBitVectorMapToSave(bitVectorMap, filename)
    if bitVectorMap ~= nil then
        table.insert(self.bitVectorMapsToSave, {
            ["bitVectorMap"] = bitVectorMap,
            ["filename"] = filename
        })
    end
end
function ValueMap:addBitVectorMapToDelete(bitVectorMap)
    if bitVectorMap ~= nil then
        table.insert(self.bitVectorMapsToDelete, {
            ["bitVectorMap"] = bitVectorMap
        })
    end
end
function ValueMap:initTerrain(mission, _, _)
    if mission.densityMapSyncer ~= nil then
        local i = 1
        for i = i, #self.bitVectorMapsToSync do
            mission.densityMapSyncer:addDensityMap(self.bitVectorMapsToSync[i].bitVectorMap)
        end
    end
end
function ValueMap:delete()
    local i = 1
    for i = i, #self.bitVectorMapsToDelete do
        delete(self.bitVectorMapsToDelete[i].bitVectorMap)
    end
    self.bitVectorMapsToDelete = {}
end
function ValueMap:loadFromItemsXML(xmlFile, key) end
function ValueMap:saveToXMLFile(xmlFile, key, usedModNames) end
function ValueMap:update(dt) end
function ValueMap:buildOverlay(overlay, valueFilter, isColorBlindMode) end
function ValueMap:getDisplayValues()
    return {}
end
function ValueMap:getValueFilter()
    return {}
end
function ValueMap:getMinimapValueFilter()
    return self:getValueFilter()
end
function ValueMap:getOverviewLabel()
    return g_i18n:getText(self.label, ValueMap.MOD_NAME)
end
function ValueMap:getId()
    return self.id
end
function ValueMap:getShowInMenu()
    return true
end
function ValueMap:getAllowCoverage()
    return false
end
function ValueMap:collectFarmlandHotspotActions(actions) end
function ValueMap:setRequireMinimapDisplay(state, sourceObject, isSelected)
    if self.minimapSourceObject == nil or self.minimapSourceObject == sourceObject then
        self.requireMinimapDisplay = state
        if state then
            self.minimapSourceObject = sourceObject
            self.minimapSourceObjectSelected = isSelected
            return
        end
        self.minimapSourceObject = nil
        self.minimapSourceObjectSelected = false
    end
end
function ValueMap:getRequireMinimapDisplay()
    return self.requireMinimapDisplay, self.minimapSourceObjectSelected
end
function ValueMap:setMinimapRequiresUpdate(state)
    self.requireMinimapUpdate = state
end
function ValueMap:setMinimapMissionState(state)
    if state ~= self.minimapMissionState then
        self.minimapMissionState = state
        self:setMinimapRequiresUpdate(true)
    end
end
function ValueMap:getMinimapUpdateTimeLimit()
    return self.minimapMissionState and 1 or 0.25
end
function ValueMap:getMinimapRequiresUpdate()
    return self.requireMinimapUpdate
end
function ValueMap:getMinimapAdditionalElement()
    return nil
end
function ValueMap:setMinimapAdditionalElementRealSize(x, y)
    self.minimapAdditionalElementRealSize[1] = x
    self.minimapAdditionalElementRealSize[2] = y
end
function ValueMap:getMinimapAdditionalElementRealSize()
    return self.minimapAdditionalElementRealSize[1], self.minimapAdditionalElementRealSize[2]
end
function ValueMap:setMinimapAdditionalElementLinkNode(linkNode)
    self.minimapAdditionalElementLinkNode = linkNode
end
function ValueMap:getMinimapAdditionalElementLinkNode()
    return self.minimapAdditionalElementLinkNode
end
function ValueMap:getMinimapLabel()
    if self.minimapMissionState then
        return self.minimapLabelNameMission or self.minimapLabelName
    else
        return self.minimapLabelName
    end
end
function ValueMap:getMinimapGradientLabel()
    if self.minimapMissionState then
        return nil
    else
        return self.minimapGradientLabelName
    end
end
function ValueMap:getMinimapGradientSliceId(isColorBlindMode)
    return isColorBlindMode and self.minimapGradientColorBlindSliceId or self.minimapGradientSliceId
end
function ValueMap:getMinimapZoomFactor()
    return 3
end
function ValueMap:collectFieldInfos(fieldInfoDisplayExtension) end
function ValueMap:getHelpLinePage()
    return 0
end
function ValueMap.roundToPixelCenter(x, z, terrainSize, mapSize)
    x = MathUtil.round((x + terrainSize * 0.5) / terrainSize * mapSize - 0.5) + 0.5
    z = MathUtil.round((z + terrainSize * 0.5) / terrainSize * mapSize - 0.5) + 0.5
    return x / mapSize * terrainSize - terrainSize * 0.5, z / mapSize * terrainSize - terrainSize * 0.5
end
function ValueMap:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(DensityMapHeightManager, "saveCollisionMap", function(superFunc, densityMapHeightManager, directory)
        -- upvalues: (copy) self
        local i = 1
        for i = i, #self.bitVectorMapsToSave do
            local bitVectorMapToSave = self.bitVectorMapsToSave[i]
            saveBitVectorMapToFile(bitVectorMapToSave.bitVectorMap, directory .. "/" .. bitVectorMapToSave.filename)
        end
        superFunc(densityMapHeightManager, directory)
    end)
    pfModule:overwriteGameFunction(DensityMapHeightManager, "prepareSaveCollisionMap", function(superFunc, densityMapHeightManager, directory)
        -- upvalues: (copy) self
        local i = 1
        for i = i, #self.bitVectorMapsToSave do
            local bitVectorMapToSave = self.bitVectorMapsToSave[i]
            prepareSaveBitVectorMapToFile(bitVectorMapToSave.bitVectorMap, directory .. "/" .. bitVectorMapToSave.filename)
        end
        superFunc(densityMapHeightManager, directory)
    end)
    pfModule:overwriteGameFunction(DensityMapHeightManager, "savePreparedCollisionMap", function(superFunc, densityMapHeightManager, callback, callbackObject)
        -- upvalues: (copy) self
        local localFuncObject = {
            ["saveBitVectorMap"] = function(index)
                -- upvalues: (ref) self, (copy) localFuncObject, (copy) superFunc, (copy) densityMapHeightManager, (copy) callback, (copy) callbackObject
                savePreparedBitVectorMapToFile(self.bitVectorMapsToSave[index].bitVectorMap, "tempCallback", {
                    ["tempCallback"] = function()
                        -- upvalues: (ref) self, (copy) index, (ref) localFuncObject, (ref) superFunc, (ref) densityMapHeightManager, (ref) callback, (ref) callbackObject
                        if index < #self.bitVectorMapsToSave then
                            localFuncObject.saveBitVectorMap(index + 1)
                        else
                            superFunc(densityMapHeightManager, callback, callbackObject)
                        end
                    end
                })
            end
        }
        if #self.bitVectorMapsToSave >= 1 then
            localFuncObject.saveBitVectorMap(1)
        else
            superFunc(densityMapHeightManager, callback, callbackObject)
        end
    end)
end