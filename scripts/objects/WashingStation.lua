WashingStation = {}
local WashingStation_mt = Class(WashingStation, Object)
InitStaticObjectClass(WashingStation, "WashingStation")
function WashingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trigger#node", "Vehicle trigger node")
    schema:register(XMLValueType.FLOAT, basePath .. "#washDuration", "Wash duration")
    schema:register(XMLValueType.INT, basePath .. "#pricePerWash", "Price per wash")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".effects")
end
function WashingStation.new(isServer, isClient, customMt)
    -- upvalues: (copy) WashingStation_mt
    return Object.new(isServer, isClient, customMt or WashingStation_mt)
end
function WashingStation:load(components, xmlFile, key, _, i3dMappings, rootNode)
    local trigger = xmlFile:getValue(key .. ".trigger#node", rootNode, components, i3dMappings)
    if trigger == nil then
        return false
    end
    self.trigger = trigger
    addTrigger(trigger, "onTriggerCallback", self)
    self.isEnabled = true
    self.vehicleNodesInRange = {}
    self.vehiclesToWash = {}
    self.pricePerWash = xmlFile:getValue(key .. "#pricePerWash", 1)
    self.washDuration = xmlFile:getValue(key .. "#washDuration", 1) * 1000
    if self.isClient then
        local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
        self.samples = {
            ["active"] = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", baseDirectory, components, 0, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        }
        self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", components, self, i3dMappings)
        self.fxActive = false
    end
    self.activatable = WashingStationActivatable.new(self, self.trigger)
    self.dirtyFlag = self:getNextDirtyFlag()
    return true
end
function WashingStation:delete()
    if self.trigger ~= nil then
        removeTrigger(self.trigger)
    end
    if self.isClient then
        g_soundManager:stopSamples(self.samples)
        g_soundManager:deleteSamples(self.samples)
        g_effectManager:deleteEffects(self.effects)
    end
    self.vehicleNodesInRange = {}
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end
function WashingStation:readUpdateStream(streamId, timestamp, connection)
    WashingStation:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:onStartWashing()
            return
        end
        self:onStopWashing()
    end
end
function WashingStation:writeUpdateStream(streamId, connection, dirtyMask)
    WashingStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.endTime ~= nil)
    end
end
function WashingStation:update(dt)
    if self.isServer and self.endTime ~= nil then
        if self.endTime > g_time then
            local i = #self.vehiclesToWash
            for i = i, 1, -1 do
                local vehicle = self.vehiclesToWash[i]
                if vehicle:getDirtAmount() > 0.01 then
                    vehicle:cleanVehicle(1 / self.washDuration * dt)
                else
                    table.remove(self.vehiclesToWash, i)
                end
            end
            self:raiseActive()
            return
        end
        self:onStopWashing()
    end
end
function WashingStation:startWashing(farmId)
    if self.isServer then
        local isWashing = false
        local costs = 0
        for node, _ in pairs(self.vehicleNodesInRange) do
            if entityExists(node) then
                local vehicle = g_currentMission:getNodeObject(node)
                if ({})[vehicle] == nil then
                    local dirtAmount = vehicle:getDirtAmount()
                    if dirtAmount > 0.01 then
                        isWashing = true
                        table.insert(self.vehiclesToWash, vehicle)
                    end
                    washedVehicles[vehicle] = true
                end
            else
                self.vehicleNodesInRange[node] = nil
            end
        end
        if isWashing then
            if costs >= 1 then
                g_currentMission:addMoney(-costs, farmId, MoneyType.VEHICLE_REPAIR, true, true)
            end
            self:onStartWashing()
        end
    end
end
function WashingStation:onStartWashing()
    if self.isServer then
        self.endTime = g_time + self.washDuration
        self:raiseActive()
        self:raiseDirtyFlags(self.dirtyFlag)
    end
    if self.isClient and not self.fxActive then
        g_soundManager:playSample(self.samples.active)
        g_effectManager:setEffectTypeInfo(self.effects, FillType.WATER)
        g_effectManager:startEffects(self.effects)
        self.fxActive = true
    end
end
function WashingStation:onStopWashing()
    if self.isServer then
        local i = #self.vehiclesToWash
        for i = i, 1, -1 do
            self.vehiclesToWash[i] = nil
        end
        self:raiseDirtyFlags(self.dirtyFlag)
    end
    if self.isClient and self.fxActive then
        g_soundManager:stopSample(self.samples.active)
        g_effectManager:stopEffects(self.effects)
        self.fxActive = false
    end
end
function WashingStation:updateVehicleState()
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    if self.isEnabled then
        local canBeActivated = self.isPlayerInRange
        if not canBeActivated then
            for node, _ in pairs(self.vehicleNodesInRange) do
                if entityExists(node) then
                    local vehicle = g_currentMission:getNodeObject(node)
                    if vehicle ~= nil and vehicle == g_localPlayer:getCurrentVehicle() then
                        canBeActivated = true
                    end
                else
                    self.vehicleNodesInRange[node] = nil
                end
            end
        end
        if canBeActivated then
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
        end
    end
end
function WashingStation:onTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if onEnter or onLeave then
        local changed = nil
        if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
            local object = g_currentMission:getNodeObject(otherId)
            if object ~= nil and (object:isa(Vehicle) and (object.getAllowsWashingByType ~= nil and object:getAllowsWashingByType(Washable.WASHTYPE_TRIGGER))) then
                if onEnter then
                    self.vehicleNodesInRange[otherId] = true
                    changed = true
                else
                    self.vehicleNodesInRange[otherId] = nil
                    changed = true
                end
            end
        elseif onEnter then
            self.isPlayerInRange = true
            changed = true
        else
            self.isPlayerInRange = false
            changed = true
        end
        if changed then
            self:updateVehicleState()
        end
    end
end
WashingStationActivatable = {}
local WashingStationActivatable_mt = Class(WashingStationActivatable)
function WashingStationActivatable.new(washingStation, triggerNode)
    -- upvalues: (copy) WashingStationActivatable_mt
    local self = setmetatable({}, WashingStationActivatable_mt)
    self.washingStation = washingStation
    self.triggerNode = triggerNode
    self.activateText = g_i18n:getText("action_startWashing")
    return self
end
function WashingStationActivatable:getIsActivatable()
    return g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), self.washingStation)
end
function WashingStationActivatable:run()
    g_client:getServerConnection():sendEvent(WashingStationEvent.new(self.washingStation))
end
function WashingStationActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.triggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end