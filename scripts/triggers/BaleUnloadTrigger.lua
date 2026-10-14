BaleUnloadTrigger = {}
local BaleUnloadTrigger_mt = Class(BaleUnloadTrigger, UnloadTrigger)
UnloadTrigger.registerCustomTrigger("baleTrigger", BaleUnloadTrigger)
InitStaticObjectClass(BaleUnloadTrigger, "BaleUnloadTrigger")
function BaleUnloadTrigger.registerXMLPaths(schema, basePath)
    UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.FLOAT, basePath .. "#deleteLitersPerSecond", "Delete liters per second", 4000)
    FillTypeManager.registerConfigXMLFilltypes(schema, basePath)
end
function BaleUnloadTrigger.new(isServer, isClient, customMt)
    -- upvalues: (copy) BaleUnloadTrigger_mt
    local self = UnloadTrigger.new(isServer, isClient, customMt or BaleUnloadTrigger_mt)
    self.triggerNode = nil
    self.balesInTrigger = {}
    return self
end
function BaleUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    if not BaleUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
        return false
    end
    self.triggerNode = xmlFile:getValue(xmlNode .. "#triggerNode", nil, components, i3dMappings)
    if self.triggerNode == nil then
        Logging.xmlError(xmlFile, "Bale trigger \'%s\' not specified", xmlNode .. "#triggerNode")
        return false
    end
    if not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.DYNAMIC_OBJECT) then
        Logging.xmlError(xmlFile, "Bale trigger \'%s\' does not have Bit \'%d\' (%s) set", xmlNode .. "#triggerNode", CollisionFlag.getBit(CollisionFlag.DYNAMIC_OBJECT), "TRIGGER_DYNAMIC_OBJECT")
        return false
    end
    if Platform.gameplay.automaticBaleDrop and not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.VEHICLE) then
        Logging.xmlError(xmlFile, "Bale trigger \'%s\' does not have Bit \'%d\' (%s) set, which is required for automatic bale loader unloading", xmlNode .. "#triggerNode", CollisionFlag.getBit(CollisionFlag.VEHICLE), "TRIGGER_VEHICLE")
        return false
    end
    if self.isServer then
        addTrigger(self.triggerNode, "baleTriggerCallback", self)
    end
    self.deleteLitersPerMS = xmlFile:getValue(xmlNode .. "#deleteLitersPerSecond", 4000) / 1000
    return true
end
function BaleUnloadTrigger:delete()
    if self.isServer and self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
    end
    self.triggerNode = nil
    self.balesInTrigger = nil
    BaleUnloadTrigger:superClass().delete(self)
end
function BaleUnloadTrigger:getIsBaleSupportedByUnloadTrigger(bale)
    local fillType = bale:getFillType()
    if self.supportedFillTypes == nil or self.supportedFillTypes[fillType] ~= nil then
        return self:getIsFillTypeAllowed(fillType) and (self:getIsFillTypeSupported(fillType) and self:getIsToolTypeAllowed(ToolType.BALE)) and true or false
    else
        return false
    end
end
function BaleUnloadTrigger:update(dt)
    BaleUnloadTrigger:superClass().update(self, dt)
    if self.isServer then
        for index, bale in ipairs(self.balesInTrigger) do
            if bale == nil or bale.nodeId == 0 then
                table.remove(self.balesInTrigger, index)
                break
            end
            if bale:getCanBeSold() and bale.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
                local fillType = bale:getFillType()
                local fillLevel = bale:getFillLevel()
                local delta = bale:getFillLevel()
                if self.deleteLitersPerMS ~= nil then
                    delta = self.deleteLitersPerMS * dt
                end
                if delta > 0 then
                    local baleOwnerFarmId = bale:getOwnerFarmId()
                    bale:setFillLevel(fillLevel - self:addFillUnitFillLevel(baleOwnerFarmId, 1, delta, fillType, ToolType.BALE, nil))
                    if bale:getFillLevel() < 0.01 then
                        if fillType == FillType.COTTON then
                            local total, _ = g_farmManager:updateFarmStats(baleOwnerFarmId, "soldCottonBales", 1)
                            if total ~= nil then
                                g_achievementManager:tryUnlock("CottonBales", total)
                            end
                        end
                        bale:delete()
                        table.remove(self.balesInTrigger, index)
                        break
                    end
                end
            end
        end
        if #self.balesInTrigger > 0 then
            self:raiseActive()
        end
    end
end
function BaleUnloadTrigger:baleTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if self.isEnabled then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil then
            if object:isa(Bale) then
                if onEnter then
                    if self:getIsBaleSupportedByUnloadTrigger(object) then
                        self:raiseActive()
                        table.addElement(self.balesInTrigger, object)
                        return
                    end
                elseif onLeave then
                    for index, bale in ipairs(self.balesInTrigger) do
                        if bale == object then
                            table.remove(self.balesInTrigger, index)
                            return
                        end
                    end
                    return
                end
            elseif object:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, object.specializations) then
                if onEnter then
                    object:addBaleUnloadTrigger(self)
                    return
                end
                if onLeave then
                    object:removeBaleUnloadTrigger(self)
                end
            end
        end
    end
end