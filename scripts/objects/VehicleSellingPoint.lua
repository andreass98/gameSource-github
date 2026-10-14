VehicleSellingPoint = {}
local VehicleSellingPoint_mt = Class(VehicleSellingPoint)
function VehicleSellingPoint.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#playerTriggerNode", "Player trigger node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#iconNode", "Icon node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#sellTriggerNode", "Sell trigger node")
    schema:register(XMLValueType.BOOL, basePath .. "#ownWorkshop", "Owned by player", false)
    schema:register(XMLValueType.BOOL, basePath .. "#mobileWorkshop", "Workshop is on vehicle", false)
end
function VehicleSellingPoint.new()
    -- upvalues: (copy) VehicleSellingPoint_mt
    local self = setmetatable({}, VehicleSellingPoint_mt)
    self.vehicleShapesInRange = {}
    self.activateText = ""
    self.isEnabled = true
    return self
end
function VehicleSellingPoint:load(components, xmlFile, key, i3dMappings)
    self.playerTrigger = xmlFile:getValue(key .. "#playerTriggerNode", nil, components, i3dMappings)
    self.sellIcon = xmlFile:getValue(key .. "#iconNode", nil, components, i3dMappings)
    self.sellTriggerNode = xmlFile:getValue(key .. "#sellTriggerNode", nil, components, i3dMappings)
    self.ownWorkshop = xmlFile:getValue(key .. "#ownWorkshop", false)
    self.mobileWorkshop = xmlFile:getValue(key .. "#mobileWorkshop", false)
    if not CollisionFlag.getHasMaskFlagSet(self.playerTrigger, CollisionFlag.PLAYER) then
        Logging.xmlWarning(xmlFile, "Missing collision mask bit \'%d\'. Please add this bit to vehicle selling player trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(self.playerTrigger))
    end
    addTrigger(self.playerTrigger, "triggerCallback", self)
    if not CollisionFlag.getHasMaskFlagSet(self.sellTriggerNode, CollisionFlag.VEHICLE) then
        Logging.xmlWarning(xmlFile, "Missing collision mask bit \'%d\'. Please add this bit to vehicle sell area trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.VEHICLE), I3DUtil.getNodePath(self.sellTriggerNode))
    end
    addTrigger(self.sellTriggerNode, "sellAreaTriggerCallback", self)
    self.activatable = VehicleSellingPointActivatable.new(self, self.ownWorkshop)
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
    g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.playerFarmChanged, self)
    self:updateIconVisibility()
end
function VehicleSellingPoint:delete()
    g_messageCenter:unsubscribeAll(self)
    if self.playerTrigger ~= nil then
        removeTrigger(self.playerTrigger)
        self.playerTrigger = nil
    end
    if self.sellTriggerNode ~= nil then
        removeTrigger(self.sellTriggerNode)
        self.sellTriggerNode = nil
    end
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    self.sellIcon = nil
end
function VehicleSellingPoint:openMenu()
    local vehicles = self:determineCurrentVehicles()
    g_workshopScreen:setSellingPoint(self, not self.ownWorkshop, self.ownWorkshop, self.mobileWorkshop)
    g_workshopScreen:setVehicles(vehicles)
    g_gui:showGui("WorkshopScreen")
end
function VehicleSellingPoint:triggerCallback(_, otherId, onEnter, onLeave, _)
    if self.isEnabled and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        self:determineCurrentVehicles()
    end
end
function VehicleSellingPoint:sellAreaTriggerCallback(_, _, onEnter, onLeave, _, otherShapeId)
    if otherShapeId ~= nil and (onEnter or onLeave) then
        if onEnter then
            self.vehicleShapesInRange[otherShapeId] = true
        elseif onLeave then
            self.vehicleShapesInRange[otherShapeId] = nil
        end
        g_workshopScreen:updateVehicles(self, self:determineCurrentVehicles())
    end
end
function VehicleSellingPoint:determineCurrentVehicles()
    local vehicles = {}
    local playerFarmId = g_currentMission:getFarmId()
    if playerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
        for shapeId, inRange in pairs(self.vehicleShapesInRange) do
            if inRange == nil or not entityExists(shapeId) then
                self.vehicleShapesInRange[shapeId] = nil
            else
                local vehicle = g_currentMission.nodeToObject[shapeId]
                if vehicle ~= nil and vehicle:isa(Vehicle) then
                    local subVehicles = vehicle.rootVehicle:getChildVehicles()
                    for _, subVehicle in ipairs(subVehicles) do
                        if subVehicle:getShowInVehiclesOverview() and subVehicle:getOwnerFarmId() == playerFarmId then
                            table.addElement(vehicles, subVehicle)
                        end
                    end
                end
            end
        end
        table.sort(vehicles, function(a, b)
            return a.rootNode < b.rootNode
        end)
    end
    return vehicles
end
function VehicleSellingPoint:updateIconVisibility()
    if self.sellIcon ~= nil then
        local isAvailable = self.isEnabled
        if isAvailable then
            isAvailable = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
        end
        local farmId = g_currentMission:getFarmId()
        local visibleForFarm = false
        if farmId ~= FarmManager.SPECTATOR_FARM_ID then
            visibleForFarm = true
            if self:getOwnerFarmId() ~= AccessHandler.EVERYONE then
                visibleForFarm = farmId == self:getOwnerFarmId()
            end
        end
        setVisibility(self.sellIcon, isAvailable and visibleForFarm)
    end
end
function VehicleSellingPoint:playerFarmChanged(player)
    if player == g_localPlayer then
        self:updateIconVisibility()
    end
end
function VehicleSellingPoint:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
    self:updateIconVisibility()
end
function VehicleSellingPoint:getOwnerFarmId()
    return self.ownerFarmId
end
VehicleSellingPointActivatable = {}
local VehicleSellingPointActivatable_mt = Class(VehicleSellingPointActivatable)
function VehicleSellingPointActivatable.new(sellingPoint, ownWorkshop)
    -- upvalues: (copy) VehicleSellingPointActivatable_mt
    local self = setmetatable({}, VehicleSellingPointActivatable_mt)
    self.sellingPoint = sellingPoint
    if ownWorkshop then
        self.activateText = g_i18n:getText("action_openWorkshopOptions")
        return self
    else
        self.activateText = g_i18n:getText("action_openDealerOptions")
        return self
    end
end
function VehicleSellingPointActivatable:getIsActivatable()
    if not self.sellingPoint.isEnabled then
        return false
    end
    if g_localPlayer:getIsInVehicle() then
        return false
    end
    local farmId = g_currentMission:getFarmId()
    if farmId == FarmManager.SPECTATOR_FARM_ID then
        return false
    end
    return self.sellingPoint:getOwnerFarmId() == AccessHandler.EVERYONE or farmId == self.sellingPoint:getOwnerFarmId()
end
function VehicleSellingPointActivatable:run()
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
    else
        self.sellingPoint:openMenu()
    end
end
function VehicleSellingPointActivatable:getDistance(x, _, z)
    local tx, _, tz = getWorldTranslation(self.sellingPoint.playerTrigger)
    return MathUtil.getPointPointDistance(tx, tz, x, z)
end