PalletUnloadTrigger = {}
source("dataS/scripts/triggers/PalletUnloadTriggerActivatable.lua")
local PalletUnloadTrigger_mt = Class(PalletUnloadTrigger, UnloadTrigger)
UnloadTrigger.registerCustomTrigger("palletTrigger", PalletUnloadTrigger)
InitStaticObjectClass(PalletUnloadTrigger, "PalletUnloadTrigger")
function PalletUnloadTrigger.registerXMLPaths(schema, basePath)
    UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.BOOL, basePath .. "#autoUnload", "Auto unload pallets", true)
    schema:register(XMLValueType.BOOL, basePath .. "#autoUnloadStrapped", "Auto unload pallets that are fasten with tension belts", false)
end
function PalletUnloadTrigger.new(isServer, isClient, customMt)
    -- upvalues: (copy) PalletUnloadTrigger_mt
    local self = UnloadTrigger.new(isServer, isClient, customMt or PalletUnloadTrigger_mt)
    self.triggerNode = nil
    self.activatable = PalletUnloadTriggerActivatable.new(self)
    self.isPlayerInRange = false
    self.isEnabled = true
    self.palletsInRange = {}
    self.vehiclesInRange = {}
    self.autoUnload = true
    self.autoUnloadStrapped = false
    return self
end
function PalletUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    if not PalletUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
        return false
    end
    local triggerNodeKey = xmlNode .. "#triggerNode"
    self.triggerNode = xmlFile:getValue(triggerNodeKey, nil, components, i3dMappings)
    if self.triggerNode == nil then
        Logging.xmlError(xmlFile, "Pallet trigger %q not specified!", triggerNodeKey)
        return false
    end
    local colMask = getCollisionFilterMask(self.triggerNode)
    if bit32.band(CollisionFlag.VEHICLE, colMask) == 0 then
        Logging.xmlError(xmlFile, "Invalid collision mask for pallet trigger \'%s\'. %s needs to be set!", triggerNodeKey, CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
        return false
    end
    addTrigger(self.triggerNode, "palletTriggerCallback", self)
    self.autoUnload = xmlFile:getValue(xmlNode .. "#autoUnload", self.autoUnload)
    self.autoUnloadStrapped = xmlFile:getValue(xmlNode .. "#autoUnloadStrapped", self.autoUnloadStrapped)
    return true
end
function PalletUnloadTrigger:delete()
    if self.triggerNode ~= nil and self.triggerNode ~= 0 then
        removeTrigger(self.triggerNode)
        self.triggerNode = 0
    end
    if self.palletsInRange ~= nil then
        for _, pallet in ipairs(self.palletsInRange) do
            if pallet.removeDeleteListener ~= nil then
                pallet:removeDeleteListener(self, "onObjectDeleted")
            end
        end
        table.clear(self.palletsInRange)
    end
    if self.vehiclesInRange ~= nil then
        table.clear(self.vehiclesInRange)
    end
    PalletUnloadTrigger:superClass().delete(self)
end
function PalletUnloadTrigger:update(dt)
    PalletUnloadTrigger:superClass().update(self, dt)
    if self.isServer and next(self.palletsInRange) ~= nil then
        self:unloadPallets()
        if next(self.palletsInRange) ~= nil then
            self:raiseActive()
        end
    end
end
function PalletUnloadTrigger:unloadPallets(farmId)
    if self.isServer then
        local mission = g_currentMission
        for _, pallet in ipairs(self.palletsInRange) do
            if farmId == nil or mission.accessHandler:canFarmAccess(farmId, pallet) then
                local fillUnits = pallet:getFillUnits()
                for fillUnitIndex, _ in pairs(fillUnits) do
                    local fillTypeIndex = pallet:getFillUnitFillType(fillUnitIndex)
                    if fillTypeIndex ~= FillType.UNKNOWN and self:getIsFillTypeSupported(fillTypeIndex) then
                        local fillLevel = pallet:getFillUnitFillLevel(fillUnitIndex)
                        if fillLevel > 0 then
                            local isAllowed = true
                            if pallet.dynamicMountType ~= nil and pallet.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
                                if self.autoUnloadStrapped then
                                    pallet:unmountDynamic()
                                else
                                    isAllowed = false
                                    if self.isServer then
                                        self:raiseActive()
                                    end
                                end
                            end
                            if isAllowed then
                                if pallet.getPalletUnloadTriggerExtraSellPrice ~= nil and (self.target ~= nil and self.target.moneyChangeType ~= nil) then
                                    mission:addMoney(pallet:getPalletUnloadTriggerExtraSellPrice(), pallet:getOwnerFarmId(), self.target.moneyChangeType, true)
                                end
                                local used = self:addFillUnitFillLevel(pallet:getOwnerFarmId(), fillUnitIndex, fillLevel, fillTypeIndex, ToolType.UNDEFINED)
                                pallet:addFillUnitFillLevel(pallet:getOwnerFarmId(), fillUnitIndex, -used, fillTypeIndex, ToolType.UNDEFINED)
                                if pallet:getFillUnitFillLevel(fillUnitIndex) < 1 then
                                    pallet:delete()
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        g_client:getServerConnection():sendEvent(PalletUnloadTriggerEvent.new(self))
    end
end
function PalletUnloadTrigger:updateActivatableObject()
    if self.isPlayerInRange or next(self.vehiclesInRange) ~= nil then
        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
    else
        mission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end
function PalletUnloadTrigger:onObjectDeleted(object)
    table.removeElement(self.palletsInRange, object)
    self.vehiclesInRange[object] = nil
end
function PalletUnloadTrigger:palletTriggerCallback(_, otherId, onEnter, _, _, _)
    if otherId ~= 0 then
        local object = g_currentMission:getNodeObject(otherId)
        if object ~= nil and (object.isPallet and object.getFillUnits ~= nil) then
            if onEnter then
                local fillUnits = object:getFillUnits()
                for fillUnitIndex, _ in pairs(fillUnits) do
                    local fillTypeIndex = object:getFillUnitFillType(fillUnitIndex)
                    if fillTypeIndex ~= FillType.UNKNOWN and (self:getIsFillTypeSupported(fillTypeIndex) and object:getFillUnitFillLevel(fillUnitIndex) > 0) then
                        table.addElement(self.palletsInRange, object)
                        object:addDeleteListener(self, "onObjectDeleted")
                    end
                end
                if self.autoUnload and self.isServer then
                    self:unloadPallets()
                end
            else
                table.removeElement(self.palletsInRange, object)
                object:removeDeleteListener(self, "onObjectDeleted")
            end
        end
        if not self.autoUnload then
            if object == nil then
                if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
                    if onEnter then
                        self.isPlayerInRange = true
                    else
                        self.isPlayerInRange = false
                    end
                end
            elseif object:isa(Vehicle) then
                if onEnter then
                    if self.vehiclesInRange[object] == nil then
                        self.vehiclesInRange[object] = 0
                        object:addDeleteListener(self, "onObjectDeleted")
                    end
                    self.vehiclesInRange[object] = self.vehiclesInRange[object] + 1
                elseif self.vehiclesInRange[object] ~= nil then
                    self.vehiclesInRange[object] = self.vehiclesInRange[object] - 1
                    if self.vehiclesInRange[object] == 0 then
                        self.vehiclesInRange[object] = nil
                        object:removeDeleteListener(self, "onObjectDeleted")
                    end
                end
            end
        end
        self:updateActivatableObject()
    end
end
function PalletUnloadTrigger:getNeedRaiseActive()
    return false
end