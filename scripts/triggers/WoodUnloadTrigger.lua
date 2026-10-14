WoodUnloadTrigger = {}
source("dataS/scripts/triggers/WoodUnloadTriggerEvent.lua")
source("dataS/scripts/triggers/WoodUnloadTriggerActivatable.lua")
local WoodUnloadTrigger_mt = Class(WoodUnloadTrigger, UnloadTrigger)
UnloadTrigger.registerCustomTrigger("woodTrigger", WoodUnloadTrigger)
InitStaticObjectClass(WoodUnloadTrigger, "WoodUnloadTrigger")
function WoodUnloadTrigger.registerXMLPaths(schema, basePath)
    UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#activationTriggerNode", "Activation trigger node for the player")
    schema:register(XMLValueType.BOOL, basePath .. "#autoUnload", "Wood is automatically unloaded", false)
    schema:register(XMLValueType.STRING, basePath .. "#trainSystemId", "Money will be added to the account of the current rental farm id of the train. This attribute is the unique id of the corresponding train system.")
end
function WoodUnloadTrigger.new(isServer, isClient, customMt)
    -- upvalues: (copy) WoodUnloadTrigger_mt
    local self = UnloadTrigger.new(isServer, isClient, customMt or WoodUnloadTrigger_mt)
    self.triggerNode = nil
    self.woodInTrigger = {}
    self.vehiclesInTrigger = {}
    self.lastSplitShapeVolume = 0
    self.lastSplitType = nil
    self.lastSplitShapeStats = {
        ["sizeX"] = 0,
        ["sizeY"] = 0,
        ["sizeZ"] = 0,
        ["numConvexes"] = 0,
        ["numAttachments"] = 0
    }
    self.extraAttributes = {
        ["price"] = 1
    }
    return self
end
function WoodUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    if not WoodUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
        return false
    end
    local triggerNodeKey = xmlNode .. "#triggerNode"
    self.triggerNode = xmlFile:getValue(triggerNodeKey, nil, components, i3dMappings)
    if self.triggerNode == nil then
        return false
    end
    local colMask = getCollisionFilterMask(self.triggerNode)
    if bit32.band(CollisionFlag.TREE, colMask) == 0 then
        Logging.xmlWarning(xmlFile, "Invalid collision filter mask for wood trigger \'%s\'. %s needs to be set!", triggerNodeKey, CollisionFlag.getBitAndName(CollisionFlag.TREE))
        return false
    end
    addTrigger(self.triggerNode, "woodTriggerCallback", self)
    local colMask = xmlFile:getValue(xmlNode .. "#activationTriggerNode", nil, components, i3dMappings)
    if colMask ~= nil then
        if not CollisionFlag.getHasMaskFlagSet(colMask, CollisionFlag.PLAYER) then
            Logging.xmlWarning(xmlFile, "Missing collision filter mask \'%s\'. Please add this bit to sell trigger node \'%s\' in \'placeable.woodSellingStation#sellTrigger\'.", CollisionFlag.getBitAndName(CollisionFlag.PLAYER), getName(colMask))
            return false
        end
        self.activationTrigger = colMask
        if self.activationTrigger ~= nil then
            addTrigger(self.activationTrigger, "woodSellTriggerCallback", self)
        end
    end
    self.autoUnload = xmlFile:getValue(xmlNode .. "#autoUnload", false)
    self.isManualSellingActive = true
    self.trainSystemId = xmlFile:getValue(xmlNode .. "#trainSystemId")
    self.trainSystem = nil
    self.activatable = WoodUnloadTriggerActivatable.new(self)
    return true
end
function WoodUnloadTrigger:delete()
    if self.triggerNode ~= nil and self.triggerNode ~= 0 then
        removeTrigger(self.triggerNode)
        self.triggerNode = 0
    end
    if self.activationTrigger ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        removeTrigger(self.activationTrigger)
        self.activationTrigger = nil
    end
    WoodUnloadTrigger:superClass().delete(self)
end
function WoodUnloadTrigger:processWood(farmId, _)
    if not self.isServer then
        g_client:getServerConnection():sendEvent(WoodUnloadTriggerEvent.new(self, farmId))
        return
    end
    local soldWood = false
    local isFull = false
    local mission = g_currentMission
    local isServer = mission:getIsServer()
    for _, nodeId in pairs(self.woodInTrigger) do
        if self:getCanProcessWood() then
            if entityExists(nodeId) then
                soldWood = true
                local volume, qualityScale, maxSize = self:calculateWoodBaseValue(nodeId)
                self.extraAttributes.price = qualityScale
                self.extraAttributes.maxSize = maxSize
                if isServer then
                    local fillType = self:getTargetFillType(maxSize, volume)
                    if self.getFillUnitFreeCapacity == nil or self:getFillUnitFreeCapacity(nil, fillType, farmId) > volume * 0.9 then
                        self:addFillUnitFillLevel(farmId, nil, volume, fillType, ToolType.undefined, nil, self.extraAttributes)
                        self:onProcessedWood(nodeId, volume, fillType)
                        local treeObject = mission:getNodeObject(nodeId)
                        if treeObject == nil then
                            delete(nodeId)
                        else
                            treeObject:delete()
                        end
                    else
                        isFull = true
                    end
                end
            end
            if isFull then
                break
            end
            self.woodInTrigger[nodeId] = nil
        end
    end
    if soldWood and isServer then
        g_farmManager:updateFarmStats(g_localPlayer.farmId, "woodTonsSold", 0)
    end
end
function WoodUnloadTrigger:getTargetFillType(maxSize, volume)
    return FillType.WOOD
end
function WoodUnloadTrigger:getCanProcessWood()
    return true
end
function WoodUnloadTrigger:onProcessedWood(nodeId, volume, fillType)
    if nodeId ~= nil and nodeId ~= 0 then
        local mission = g_missionManager:getMissionBySplitShape(nodeId)
        if mission ~= nil and mission.onTriggerProcessedWood ~= nil then
            mission:onTriggerProcessedWood(self, nodeId, volume, fillType)
        end
    end
end
function WoodUnloadTrigger:calculateWoodBaseValue(objectId)
    local volume = getVolume(objectId)
    local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
    local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(objectId)
    return self:calculateWoodBaseValueForData(volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
end
function WoodUnloadTrigger.calculateWoodBaseValueForData(_, volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
    local qualityScale = 1
    local lengthScale = 1
    local defoliageScale = 1
    local maxSize = 0
    if sizeX ~= nil and volume > 0 then
        local maxQuality = math.clamp((sizeX * sizeY * sizeZ / volume - 3) / 7, 0, 1)
        local volumeQuality = 1 - math.sqrt(maxQuality) * 0.95
        local convexityQuality = 1 - math.clamp((numConvexes - 2) / 4, 0, 1) * 0.95
        maxSize = math.max(sizeX, sizeY, sizeZ)
        if maxSize < 11 then
            lengthScale = 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6
        else
            lengthScale = 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6
        end
        local minQuality = math.min(convexityQuality, volumeQuality)
        qualityScale = minQuality + (math.max(convexityQuality, volumeQuality) - minQuality) * 0.3
        defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8
    end
    local bvVolume = #EconomicDifficulty.getAllOrdered()
    local volumeQuality = g_currentMission.missionInfo
    local convexityQuality = MathUtil.lerp(1, qualityScale, volumeQuality.economicDifficulty / bvVolume)
    local convexityQuality = MathUtil.lerp(1, defoliageScale, volumeQuality.economicDifficulty / bvVolume)
    return volume * splitType.volumeToLiter, splitType.pricePerLiter * convexityQuality * convexityQuality * lengthScale, maxSize
end
function WoodUnloadTrigger:update(dt)
    WoodUnloadTrigger:superClass().update(self, dt)
    if self.isServer then
        local farmId = self.target:getOwnerFarmId()
        if self.trainSystemId == nil then
            if self.autoUnload then
                local placeable = next(self.vehiclesInTrigger)
                if placeable ~= nil then
                    local vehicle = g_currentMission:getNodeObject(placeable)
                    if vehicle == nil then
                        self.vehiclesInTrigger[placeable] = nil
                    else
                        farmId = vehicle:getOwnerFarmId()
                    end
                end
            end
        else
            if self.trainSystem == nil then
                local placeable = mission.placeableSystem:getPlaceableByUniqueId(self.trainSystemId)
                if placeable ~= nil and placeable.spec_trainSystem ~= nil then
                    self.trainSystem = placeable
                end
            end
            if self.trainSystem ~= nil then
                farmId = self.trainSystem.spec_trainSystem.lastRentFarmId
            end
        end
        if farmId ~= FarmManager.SPECTATOR_FARM_ID then
            self:processWood(farmId)
        end
    end
end
function WoodUnloadTrigger:woodTriggerCallback(_, otherId, onEnter, _, _, _)
    if otherId ~= 0 then
        local splitType = nil
        if getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
            splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherId))
        end
        if splitType == nil or splitType.pricePerLiter <= 0 then
            if self.autoUnload then
                local object = g_currentMission:getNodeObject(otherId)
                if object ~= nil and object:isa(Vehicle) then
                    if onEnter then
                        self.vehiclesInTrigger[otherId] = (self.vehiclesInTrigger[otherId] or 0) + 1
                        self:raiseActive()
                        return
                    end
                    self.vehiclesInTrigger[otherId] = (self.vehiclesInTrigger[otherId] or 0) - 1
                    if self.vehiclesInTrigger[otherId] <= 0 then
                        self.vehiclesInTrigger[otherId] = nil
                    end
                end
            end
        else
            if not onEnter then
                self.woodInTrigger[otherId] = nil
                return
            end
            self.woodInTrigger[otherId] = otherId
            if self:getNeedRaiseActive() then
                self:raiseActive()
                return
            end
        end
    end
end
function WoodUnloadTrigger:getNeedRaiseActive()
    return self.trainSystemId ~= nil or self.autoUnload
end
function WoodUnloadTrigger:getWoodLogs()
    return self.woodInTrigger
end
function WoodUnloadTrigger:woodSellTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
        if onEnter then
            if self.isManualSellingActive then
                g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                return
            end
        else
            mission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
    end
end