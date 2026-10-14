PrecisionFarmingDebug = {}
PrecisionFarmingDebug.MOD_NAME = g_currentModName
local PrecisionFarmingDebug_mt = Class(PrecisionFarmingDebug)
function PrecisionFarmingDebug.new(precisionFarming, customMt)
    -- upvalues: (copy) PrecisionFarmingDebug_mt
    local self = setmetatable({}, customMt or PrecisionFarmingDebug_mt)
    self.precisionFarming = precisionFarming
    addConsoleCommand("pfToggleGroundDebug", "Enables debug display of ground data", "toggleGroundDebug", self)
    return self
end
function PrecisionFarmingDebug:delete()
    removeConsoleCommand("pfToggleGroundDebug")
end
function PrecisionFarmingDebug:toggleGroundDebug()
    if self.groundDebugArea == nil then
        local nitrogenMap = self.precisionFarming.nitrogenMap
        local coverMap = self.precisionFarming.coverMap
        local pHMap = self.precisionFarming.pHMap
        local data = {}
        self.groundDebugArea = DebugBitVectorMap.newSimple(20, 2, false, 0.01, 0.1)
        self.groundDebugArea:createWithCustomFunc(function(_, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
            -- upvalues: (copy) coverMap, (copy) data, (copy) nitrogenMap, (copy) pHMap
            local centerZ = (startWorldZ + heightWorldZ) * 0.5
            local centerY, centerZ = ValueMap.roundToPixelCenter((startWorldX + widthWorldX) * 0.5, centerZ, g_terrainSize, coverMap.sizeX)
            data.valid = coverMap:getIsUncoveredAtPos(centerY, centerZ, true)
            if data.valid then
                data.nLevel = nitrogenMap:getLevelAtWorldPos(centerY, centerZ)
                data.nLevelLocked = nitrogenMap:getIsLockedAtWorldPos(centerY, centerZ, SprayType.FERTILIZER)
                local centerY = data
                centerY.nOffsetIsLocked, data.nOffset = nitrogenMap:getNOffsetDataAtWorldPos(centerY, centerZ)
                data.phLevel = pHMap:getLevelAtWorldPos(centerY, centerZ)
                data.phLevelLocked = pHMap:getIsLockedAtWorldPos(centerY, centerZ, SprayType.LIME)
                data.coverValue = coverMap:getLevelAtWorldPos(centerY, centerZ)
                data.curSprayType = g_currentMission.fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.SPRAY_TYPE, centerY, 0, centerZ)
                if -g_terrainSize * 0.5 - 0.01 < startWorldX and (startWorldX < g_terrainSize * 0.5 - 0.01 and (-g_terrainSize * 0.5 - 0.01 < startWorldZ and startWorldZ < g_terrainSize * 0.5 - 0.01)) then
                    DebugPlane.renderWithPositions(startWorldX + 0.05, 0, startWorldZ + 0.05, widthWorldX - 0.05, 0, widthWorldZ + 0.05, heightWorldX + 0.05, 0, heightWorldZ - 0.05, nil, true, false, false, false)
                    local centerY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, centerY, 0, centerZ)
                    drawDebugPoint(centerY, centerY, centerZ, 0, 1, 0, 1, false)
                end
            end
            return 1, 0
        end)
        self.groundDebugArea:setAdditionalDrawInfoFunc(function(_, x, z, _, _)
            -- upvalues: (copy) data, (copy) nitrogenMap, (copy) pHMap
            if data.valid then
                local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
                local nLevelReal = nitrogenMap:getNitrogenValueFromInternalValue(data.nLevel)
                local phLevelReal = pHMap:getPhValueFromInternalValue(data.phLevel)
                Utils.renderTextAtWorldPosition(x, y, z, string.format("N: %dkg %s(off: %d%s)\npH: %.3f %s\ncoverValue %d\n sprayType: %d", nLevelReal, data.nLevelLocked and "L " or "", data.nOffset, data.nOffsetIsLocked and " locked" or "", phLevelReal, data.phLevelLocked and "L " or "", data.coverValue, data.curSprayType), getCorrectTextSize(0.01), 0)
            end
        end)
        g_debugManager:addElement(self.groundDebugArea)
    else
        g_debugManager:removeElement(self.groundDebugArea)
        self.groundDebugArea = nil
    end
end