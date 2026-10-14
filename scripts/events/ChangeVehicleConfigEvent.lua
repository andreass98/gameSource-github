ChangeVehicleConfigEvent = {}
local ChangeVehicleConfigEvent_mt = Class(ChangeVehicleConfigEvent, Event)
InitStaticEventClass(ChangeVehicleConfigEvent, "ChangeVehicleConfigEvent")
function ChangeVehicleConfigEvent.emptyNew()
    -- upvalues: (copy) ChangeVehicleConfigEvent_mt
    return Event.new(ChangeVehicleConfigEvent_mt)
end
function ChangeVehicleConfigEvent.new(vehicle, vehicleBuyData)
    local self = ChangeVehicleConfigEvent.emptyNew()
    self.vehicle = vehicle
    self.vehicleBuyData = vehicleBuyData
    return self
end
function ChangeVehicleConfigEvent.newServerToClient(successful)
    local self = ChangeVehicleConfigEvent.emptyNew()
    self.successful = successful
    return self
end
function ChangeVehicleConfigEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.successful = streamReadBool(streamId)
    else
        self.vehicle = NetworkUtil.readNodeObject(streamId)
        self.vehicleBuyData = BuyVehicleData.new()
        self.vehicleBuyData:readStream(streamId, connection)
    end
    self:run(connection)
end
function ChangeVehicleConfigEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.vehicle)
        self.vehicleBuyData:writeStream(streamId, connection)
    else
        streamWriteBool(streamId, self.successful)
    end
end
function ChangeVehicleConfigEvent:run(connection)
    if connection:getIsServer() then
        g_workshopScreen:onVehicleChanged(self.successful)
    else
        local success = false
        local vehicle = self.vehicle
        if vehicle == nil or (not vehicle.isVehicleSaved or vehicle.getIsControlled ~= nil and vehicle:getIsControlled()) or not g_currentMission:getHasPlayerPermission("buyVehicle", connection) then
            connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(false))
        else
            local vehicleSystem = g_currentMission.vehicleSystem
            vehicle:setConfigurations(self.vehicleBuyData.configurations, self.vehicleBuyData.boughtConfigurations, self.vehicleBuyData.configurationData)
            if vehicle.setLicensePlatesData ~= nil and (vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates()) then
                vehicle:setLicensePlatesData(self.vehicleBuyData.licensePlateData)
            end
            local spec = vehicle.spec_attacherJoints
            if spec ~= nil and spec.attachedImplements ~= nil then
                local i = #spec.attachedImplements
                for i = i, 1, -1 do
                    local implement = spec.attachedImplements[i]
                    if not implement.object:getIsAdditionalAttachment() then
                        vehicle:detachImplementByObject(implement.object, true)
                    end
                end
            end
            vehicle.isReconfigurating = true
            g_server:broadcastEvent(VehicleSetIsReconfiguratingEvent.new(vehicle), nil, nil, vehicle)
            local xmlFile = vehicle:getReloadXML()
            local function asyncCallbackFunction(_, vehicles, _)
                -- upvalues: (ref) success, (copy) self, (copy) vehicle, (copy) vehicleSystem, (copy) xmlFile, (copy) connection
                if #vehicles > 0 then
                    success = true
                    g_currentMission:addMoney(-self.vehicleBuyData.price, self.vehicleBuyData.ownerFarmId, MoneyType.SHOP_VEHICLE_BUY, true)
                    vehicle:removeFromPhysics()
                    vehicle:delete(true)
                else
                    vehicle:addToPhysics()
                    vehicleSystem.vehicleByUniqueId[vehicle:getUniqueId()] = vehicle
                end
                xmlFile:delete()
                connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(success))
            end
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) vehicleSystem, (copy) vehicle, (copy) xmlFile, (copy) asyncCallbackFunction
                vehicleSystem.vehicleByUniqueId[vehicle:getUniqueId()] = nil
                vehicleSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, nil, {})
            end)
        end
    end
end