RailroadCaller = {}
function RailroadCaller.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
end
local RailroadCaller_mt = Class(RailroadCaller)
function RailroadCaller.new(isServer, isClient, trainSystem, nodeId, customMt)
    -- upvalues: (copy) RailroadCaller_mt
    local self = setmetatable({}, customMt or RailroadCaller_mt)
    self.trainSystem = trainSystem
    self.nodeId = nodeId
    self.isServer = isServer
    self.isClient = isClient
    self.activatable = RailroadCallerActivatable.new(self)
    return self
end
function RailroadCaller:loadFromXML(xmlFile, key, components, i3dMappings)
    self.triggerNode = xmlFile:getValue(key .. "#triggerNode", nil, components, i3dMappings)
    self.rootNode = self.triggerNode
    if self.triggerNode ~= nil then
        addTrigger(self.triggerNode, "railroadCallerTriggerCallback", self)
        return true
    end
    Logging.xmlWarning(xmlFile, "Missing trigger \'triggerNode\' for railroadCaller \'%s\'!", key)
    delete(xmlFile)
    return false
end
function RailroadCaller:delete()
    if self.triggerNode ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        removeTrigger(self.triggerNode)
        self.triggerNode = nil
    end
end
function RailroadCaller:setSplineTimeByPosition(t, _)
    self.splinePositionTime = SplineUtil.getValidSplineTime(t)
end
function RailroadCaller:railroadCallerTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if self.trainSystem ~= nil and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end
function RailroadCaller:callRailroad()
    if g_localPlayer.farmId == FarmManager.SPECTATOR_FARM_ID or not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE) then
        InfoDialog.show(g_i18n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION))
    elseif self.trainSystem ~= nil then
        self.trainSystem:toggleRent(g_localPlayer.farmId, self.splinePositionTime)
        return
    end
end
RailroadCallerActivatable = {}
local RailroadCallerActivatable_mt = Class(RailroadCallerActivatable)
function RailroadCallerActivatable.new(railroadCaller)
    -- upvalues: (copy) RailroadCallerActivatable_mt
    local self = setmetatable({}, RailroadCallerActivatable_mt)
    self.railroadCaller = railroadCaller
    self.trainSystem = railroadCaller.trainSystem
    self.activateTextRent = g_i18n:getText("action_rentTrain")
    self.activateTextWait = g_i18n:getText("action_waitForRentedTrain")
    self.activateTextGiveBack = g_i18n:getText("action_returnRentedTrain")
    self.activateText = self.activateTextRent
    return self
end
function RailroadCallerActivatable:getIsActivatable()
    if self.trainSystem:getCanBeRented(g_localPlayer.farmId) then
        return not g_localPlayer:getIsInVehicle()
    else
        return false
    end
end
function RailroadCallerActivatable:run()
    self.railroadCaller:callRailroad()
end
function RailroadCallerActivatable:activate()
    g_currentMission:addDrawable(self)
end
function RailroadCallerActivatable:deactivate()
    g_currentMission:removeDrawable(self)
end
function RailroadCallerActivatable:draw()
    local spec = self.trainSystem.spec_trainSystem
    if spec.isRented then
        self.activateText = self.activateTextGiveBack
        if spec.rootLocomotive ~= nil then
            local distance = spec.rootLocomotive:getDistanceToRequestedPosition()
            if distance > 0 then
                local distanceStr = string.format("%.1fkm", distance / 1000)
                if distance < 1000 then
                    distanceStr = string.format("%dm", distance)
                end
                g_currentMission:addExtraPrintText(string.format(self.activateTextWait, distanceStr))
                return
            end
        end
    else
        self.activateText = string.format(self.activateTextRent, g_i18n:formatMoney(spec.rentPricePerHour, 0, true, true))
    end
end
function RailroadCallerActivatable:getDistance(x, y, z)
    if self.railroadCaller.triggerNode == nil then
        return math.huge
    end
    local tx, ty, tz = getWorldTranslation(self.railroadCaller.triggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end