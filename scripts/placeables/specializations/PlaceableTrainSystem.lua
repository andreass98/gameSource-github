PlaceableTrainSystem = {}
source("dataS/scripts/placeables/specializations/events/PlaceableTrainSystemRentEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableTrainSystemSellEvent.lua")
function PlaceableTrainSystem.prerequisitesPresent(specializations)
    return true
end
function PlaceableTrainSystem.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateRailroadVehiclePositions", PlaceableTrainSystem.updateRailroadVehiclePositions)
    SpecializationUtil.registerFunction(placeableType, "createVehicles", PlaceableTrainSystem.createVehicles)
    SpecializationUtil.registerFunction(placeableType, "railroadVehicleLoaded", PlaceableTrainSystem.railroadVehicleLoaded)
    SpecializationUtil.registerFunction(placeableType, "finalizeTrain", PlaceableTrainSystem.finalizeTrain)
    SpecializationUtil.registerFunction(placeableType, "setIsTrainTabbable", PlaceableTrainSystem.setIsTrainTabbable)
    SpecializationUtil.registerFunction(placeableType, "getIsTrainInDriveableRange", PlaceableTrainSystem.getIsTrainInDriveableRange)
    SpecializationUtil.registerFunction(placeableType, "getSplineTime", PlaceableTrainSystem.getSplineTime)
    SpecializationUtil.registerFunction(placeableType, "setSplineTime", PlaceableTrainSystem.setSplineTime)
    SpecializationUtil.registerFunction(placeableType, "addSplinePositionUpdateListener", PlaceableTrainSystem.addSplinePositionUpdateListener)
    SpecializationUtil.registerFunction(placeableType, "removeSplinePositionUpdateListener", PlaceableTrainSystem.removeSplinePositionUpdateListener)
    SpecializationUtil.registerFunction(placeableType, "updateTrainPositionByLocomotiveSpeed", PlaceableTrainSystem.updateTrainPositionByLocomotiveSpeed)
    SpecializationUtil.registerFunction(placeableType, "updateTrainPositionByLocomotiveSplinePosition", PlaceableTrainSystem.updateTrainPositionByLocomotiveSplinePosition)
    SpecializationUtil.registerFunction(placeableType, "updateTrainLength", PlaceableTrainSystem.updateTrainLength)
    SpecializationUtil.registerFunction(placeableType, "toggleRent", PlaceableTrainSystem.toggleRent)
    SpecializationUtil.registerFunction(placeableType, "getCanBeRented", PlaceableTrainSystem.getCanBeRented)
    SpecializationUtil.registerFunction(placeableType, "rentRailroad", PlaceableTrainSystem.rentRailroad)
    SpecializationUtil.registerFunction(placeableType, "returnRailroad", PlaceableTrainSystem.returnRailroad)
    SpecializationUtil.registerFunction(placeableType, "onDeleteObject", PlaceableTrainSystem.onDeleteObject)
    SpecializationUtil.registerFunction(placeableType, "getIsRented", PlaceableTrainSystem.getIsRented)
    SpecializationUtil.registerFunction(placeableType, "getSplineLength", PlaceableTrainSystem.getSplineLength)
    SpecializationUtil.registerFunction(placeableType, "getElectricitySpline", PlaceableTrainSystem.getElectricitySpline)
    SpecializationUtil.registerFunction(placeableType, "getElectricitySplineLength", PlaceableTrainSystem.getElectricitySplineLength)
    SpecializationUtil.registerFunction(placeableType, "getLengthSplineTime", PlaceableTrainSystem.getLengthSplineTime)
    SpecializationUtil.registerFunction(placeableType, "getSpline", PlaceableTrainSystem.getSpline)
    SpecializationUtil.registerFunction(placeableType, "updateDriveableState", PlaceableTrainSystem.updateDriveableState)
    SpecializationUtil.registerFunction(placeableType, "gsIsTrainFilled", PlaceableTrainSystem.gsIsTrainFilled)
    SpecializationUtil.registerFunction(placeableType, "onSellGoodsQuestion", PlaceableTrainSystem.onSellGoodsQuestion)
    SpecializationUtil.registerFunction(placeableType, "sellGoods", PlaceableTrainSystem.sellGoods)
    SpecializationUtil.registerFunction(placeableType, "getTrainPosition", PlaceableTrainSystem.getTrainPosition)
end
function PlaceableTrainSystem.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedDayChanged", PlaceableTrainSystem.getNeedDayChanged)
end
function PlaceableTrainSystem.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableTrainSystem)
    SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableTrainSystem)
end
function PlaceableTrainSystem.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Train")
    schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.rent#pricePerHour", "Rent price per real time hour", 0)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.spline#node", "Spline node")
    schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.spline#splineYOffset", "Spline Y offset", 0)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.drivingRange#startNode", "Start of range node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.drivingRange#endNode", "End of range node")
    schema:register(XMLValueType.STRING, basePath .. ".trainSystem.drivingRange#sellingStationId", "Unique id of selling station")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.electricitySpline#node", "Electricity spline")
    schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.electricitySpline#splineYOffset", "Electricity spline Y offset", 0)
    schema:register(XMLValueType.STRING, basePath .. ".trainSystem.train.vehicle(?)#xmlFilename", "XMl filename")
    RailroadCrossing.registerXMLPaths(schema, basePath .. ".trainSystem.railroadCrossings.railroadCrossing(?)")
    RailroadCaller.registerXMLPaths(schema, basePath .. ".trainSystem.railroadCallers.railroadCaller(?)")
    schema:setXMLSpecializationType()
end
function PlaceableTrainSystem.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Train")
    schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "Current spline time")
    schema:register(XMLValueType.BOOL, basePath .. "#isRented", "Is train rented")
    schema:register(XMLValueType.INT, basePath .. "#rentFarmId", "Train is rented by farm")
    schema:register(XMLValueType.FLOAT, basePath .. "#currentPrice", "Current pending rent price")
    schema:register(XMLValueType.STRING, basePath .. ".railroadVehicle(?)#vehicleUniqueId", "Vehicle unique id")
    schema:register(XMLValueType.INT, basePath .. ".railroadObjects(?)#index", "Object index")
    schema:setXMLSpecializationType()
end
function PlaceableTrainSystem:onLoad(_)
    local spec = self.spec_trainSystem
    spec.lastUpdateLoopIndex = -1
    spec.splineTime = -1
    spec.splineTimeSent = spec.splineTime
    spec.splineEndTime = 0
    spec.trainLengthSplineTime = 0
    spec.splinePositionUpdateListener = {}
    spec.startSplineTime = spec.startSplineTime or 0
    spec.railroadVehicles = {}
    spec.trainLength = 0
    spec.x = 0
    spec.y = 0
    spec.z = 0
    spec.splinePositionSpeedReal = 0
    spec.splinePositionSpeed = 0
    spec.firstUpdate = true
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.stationDirtyFlag = self:getNextDirtyFlag()
    spec.networkTimeInterpolator = InterpolationTime.new(1.2)
    spec.networkSplineTimeInterpolator = InterpolatorValue.new(0)
    spec.isRented = false
    spec.rentFarmId = FarmManager.SPECTATOR_FARM_ID
    spec.lastRentFarmId = FarmManager.SPECTATOR_FARM_ID
    spec.currentPrice = 0
    spec.rentPricePerHour = self.xmlFile:getValue("placeable.trainSystem.rent#pricePerHour", 0)
    spec.rentPricePerMS = spec.rentPricePerHour / 60 / 60 / 1000
    spec.rootLocomotive = nil
    spec.spline = self.xmlFile:getValue("placeable.trainSystem.spline#node", nil, self.components, self.i3dMappings)
    if spec.spline == nil then
        Logging.xmlError(self.xmlFile, "Missing spline node!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    elseif getHasClassId(getGeometry(spec.spline), ClassIds.SPLINE) then
        if getIsSplineClosed(spec.spline) then
            spec.splineLength = getSplineLength(spec.spline)
            spec.splineYOffset = self.xmlFile:getValue("placeable.trainSystem.spline#splineYOffset", 0)
            spec.splineDriveRange = { 0, 1 }
            spec.drivingRangeStart = self.xmlFile:getValue("placeable.trainSystem.drivingRange#startNode", nil, self.components, self.i3dMappings)
            spec.drivingRangeEnd = self.xmlFile:getValue("placeable.trainSystem.drivingRange#endNode", nil, self.components, self.i3dMappings)
            spec.drivingRangeSellingStationId = self.xmlFile:getValue("placeable.trainSystem.drivingRange#sellingStationId")
            spec.textDriveInfo = g_i18n:getText("ui_infoTrainDrive")
            spec.textSellQuestion = g_i18n:getText("ui_questionTrainSellGoods")
            spec.hasLimitedRange = false
            if spec.drivingRangeStart ~= nil and spec.drivingRangeEnd ~= nil then
                local nearestDistanceStart = math.huge
                local nearestDistanceEnd = math.huge
                local x1, y1, z1 = getWorldTranslation(spec.drivingRangeStart)
                local x2, y2, z2 = getWorldTranslation(spec.drivingRangeEnd)
                local i = 0
                local secondValue = 1
                for i = i, secondValue, 0.5 / spec.splineLength do
                    local sx, sy, sz = getSplinePosition(spec.spline, i)
                    local distance1 = MathUtil.vector3Length(sx - x1, sy - y1, sz - z1)
                    if distance1 < nearestDistanceStart then
                        spec.splineDriveRange[1] = i
                    else
                        distance1 = nearestDistanceStart
                    end
                    local distance2 = MathUtil.vector3Length(sx - x2, sy - y2, sz - z2)
                    if distance2 < nearestDistanceEnd then
                        spec.splineDriveRange[2] = i
                        nearestDistanceStart = distance1
                        nearestDistanceEnd = distance2
                    else
                        nearestDistanceStart = distance1
                    end
                end
                if spec.splineDriveRange[1] > spec.splineDriveRange[2] then
                    spec.splineDriveRange[2] = spec.splineDriveRange[1]
                    spec.splineDriveRange[1] = spec.splineDriveRange[2]
                end
                spec.hasLimitedRange = true
            end
            spec.sellingStationPlaceable = nil
            spec.sellingStationPlaceableId = nil
            spec.sellingStation = nil
            spec.showDialog = 0
            spec.showDialogDelay = 0
            spec.lastIsInDriveableRange = true
            spec.lastSplineTime = 0
            spec.electricitySpline = self.xmlFile:getValue("placeable.trainSystem.electricitySpline#node", nil, self.components, self.i3dMappings)
            if spec.electricitySpline ~= nil then
                if getHasClassId(getGeometry(spec.electricitySpline), ClassIds.SPLINE) then
                    if getIsSplineClosed(spec.electricitySpline) then
                        local nearestDistanceStart, nearestDistanceEnd, x1 = getSplinePosition(spec.spline, 0)
                        local y1, z1, x2 = getSplinePosition(spec.spline, 0)
                        if MathUtil.vector2Length(nearestDistanceStart - y1, x1 - x2) < 5 then
                            spec.electricitySplineLength = getSplineLength(spec.electricitySpline)
                            spec.electricitySplineYOffset = self.xmlFile:getValue("placeable.trainSystem.electricitySpline#splineYOffset", 0)
                        else
                            Logging.xmlError(self.xmlFile, "Railroad and electricity spline should almost start at the same x and z positions. Ignoring electricity spline!")
                            spec.electricitySpline = nil
                        end
                    else
                        Logging.xmlError(self.xmlFile, "Railroad electricity spline has to be closed. Ignoring electricity spline!")
                        spec.electricitySpline = nil
                    end
                else
                    Logging.xmlError(self.xmlFile, "Given electricitySpline node is not a spline. Ignoring electricity spline!")
                    spec.electricitySpline = nil
                end
            end
            spec.vehiclesToLoad = {}
            if self.isServer then
                for y1, z1 in self.xmlFile:iterator("placeable.trainSystem.train.vehicle") do
                    local x2 = self.xmlFile:getValue(z1 .. "#xmlFilename")
                    if x2 ~= nil then
                        table.insert(spec.vehiclesToLoad, x2)
                    end
                end
            end
            spec.railroadObjects = {}
            spec.railroadCrossings = {}
            for y1, z1 in self.xmlFile:iterator("placeable.trainSystem.railroadCrossings.railroadCrossing") do
                local x2 = RailroadCrossing.new(self.isServer, self.isClient, self, self.rootNode)
                if x2:loadFromXML(self.xmlFile, z1, self.components, self.i3dMappings) then
                    table.insert(spec.railroadCrossings, x2)
                    table.insert(spec.railroadObjects, x2)
                else
                    x2:delete()
                end
            end
            spec.railroadCallers = {}
            for y1, z1 in self.xmlFile:iterator("placeable.trainSystem.railroadCallers.railroadCaller") do
                local x2 = RailroadCaller.new(self.isServer, self.isClient, self, self.rootNode)
                if x2:loadFromXML(self.xmlFile, z1, self.components, self.i3dMappings) then
                    table.insert(spec.railroadCallers, x2)
                    table.insert(spec.railroadObjects, x2)
                end
            end
            local x1 = 0
            local nearestDistanceStart = 1
            local nearestDistanceEnd = 0.5 / spec.splineLength
            for x1 = x1, nearestDistanceStart, nearestDistanceEnd do
                local y1, z1, x2 = getSplinePosition(spec.spline, x1)
                for _, i in ipairs(spec.railroadObjects) do
                    local sx, sy, sz = getWorldTranslation(i.rootNode)
                    local distance1 = MathUtil.vector3Length(y1 - sx, z1 - sy, x2 - sz)
                    if i.nearestDistance == nil then
                        i.nearestDistance = distance1
                        i.nearestTime = x1
                    elseif distance1 < i.nearestDistance then
                        i.nearestDistance = distance1
                        i.nearestTime = x1
                    end
                end
            end
            spec.railroadVehiclesEndTimes = {}
            spec.railroadVehicleUpdateIndex = 0
            spec.lastVehicle = nil
            spec.numVehiclesToLoad = 0
        else
            Logging.xmlError(self.xmlFile, "Train spline is not closed. Open splines are not supported!")
            self:setLoadingState(PlaceableLoadingState.ERROR)
        end
    else
        Logging.xmlError(self.xmlFile, "Given node is not a spline!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end
end
function PlaceableTrainSystem:onDelete()
    local spec = self.spec_trainSystem
    if spec.railroadObjects ~= nil then
        for _, object in ipairs(spec.railroadObjects) do
            object:delete()
        end
    end
    if spec.railroadVehicles ~= nil then
        for _, object in ipairs(spec.railroadVehicles) do
            object.trainSystem = nil
        end
    end
    g_currentMission:removeTrainSystem(self)
end
function PlaceableTrainSystem:onFinalizePlacement()
    local spec = self.spec_trainSystem
    if spec.railroadCrossings ~= nil then
        for _, railroadCrossing in ipairs(spec.railroadCrossings) do
            railroadCrossing:findBlockingPositions()
        end
    end
    for _, railroadCrossing in ipairs(spec.railroadObjects) do
        if railroadCrossing.setSplineTimeByPosition ~= nil then
            railroadCrossing:setSplineTimeByPosition(railroadCrossing.nearestTime, spec.splineLength)
        end
        if railroadCrossing.onSplinePositionTimeUpdate ~= nil then
            railroadCrossing:onSplinePositionTimeUpdate(spec.splineTime, spec.splineEndTime)
        end
    end
    g_currentMission:addTrainSystem(self)
    if g_currentMission.isMissionStarted then
        self:createVehicles()
    else
        g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, PlaceableTrainSystem.createVehicles, self)
    end
end
function PlaceableTrainSystem:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_trainSystem
        spec.railroadVehicleIds = {}
        local numVehicles = streamReadInt8(streamId)
        local i = 1
        for i = i, numVehicles do
            spec.railroadVehicleIds[i] = NetworkUtil.readNodeObjectId(streamId)
        end
        local splineTime = streamReadFloat32(streamId)
        spec.networkSplineTimeInterpolator:setValue(splineTime)
        spec.networkTimeInterpolator:reset()
        spec.splineTime = splineTime
        for _, railroadObject in ipairs(spec.railroadObjects) do
            if railroadObject.readStream ~= nil then
                railroadObject:readStream(streamId, connection)
            end
        end
        spec.isRented = streamReadBool(streamId)
        spec.rentFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        spec.sellingStationPlaceableId = NetworkUtil.readNodeObjectId(streamId)
        self:raiseActive()
    end
end
function PlaceableTrainSystem:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_trainSystem
        local numVehicles = #spec.railroadVehicles
        streamWriteInt8(streamId, numVehicles)
        local i = 1
        for i = i, numVehicles do
            NetworkUtil.writeNodeObject(streamId, spec.railroadVehicles[i])
        end
        streamWriteFloat32(streamId, spec.splineTimeSent)
        for _, railroadObject in ipairs(spec.railroadObjects) do
            if railroadObject.writeStream ~= nil then
                railroadObject:writeStream(streamId, connection)
            end
        end
        streamWriteBool(streamId, spec.isRented)
        streamWriteUIntN(streamId, spec.rentFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        NetworkUtil.writeNodeObject(streamId, spec.sellingStationPlaceable)
    end
end
function PlaceableTrainSystem:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local splineTime = streamReadFloat32(streamId)
            self.spec_trainSystem.networkTimeInterpolator:startNewPhaseNetwork()
            spec.networkSplineTimeInterpolator:setTargetValue(splineTime)
            for _, railroadObject in ipairs(spec.railroadObjects) do
                if railroadObject.readUpdateStream ~= nil then
                    railroadObject:readUpdateStream(streamId, timestamp, connection)
                end
            end
        end
        if streamReadBool(streamId) then
            spec.sellingStationPlaceableId = NetworkUtil.readNodeObjectId(streamId)
        end
    end
end
function PlaceableTrainSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_trainSystem.dirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, spec.splineTimeSent)
            for _, railroadObject in ipairs(spec.railroadObjects) do
                if railroadObject.writeUpdateStream ~= nil then
                    railroadObject:writeUpdateStream(streamId, connection, dirtyMask)
                end
            end
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.stationDirtyFlag) ~= 0) then
            NetworkUtil.writeNodeObject(streamId, spec.sellingStationPlaceable)
        end
    end
end
function PlaceableTrainSystem:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_trainSystem
    for _, railroadKey in xmlFile:iterator(key .. ".railroadObjects") do
        local index = xmlFile:getValue(railroadKey .. "#index")
        if index ~= nil then
            local object = spec.railroadObjects[index]
            if object ~= nil then
                object:loadFromXMLFile(xmlFile, railroadKey)
            end
        end
    end
    spec.isRented = xmlFile:getValue(key .. "#isRented", spec.isRented)
    spec.rentFarmId = xmlFile:getValue(key .. "#rentFarmId", spec.rentFarmId)
    spec.lastRentFarmId = spec.rentFarmId
    spec.currentPrice = xmlFile:getValue(key .. "#currentPrice", spec.currentPrice)
    spec.startSplineTime = SplineUtil.getValidSplineTime(xmlFile:getValue(key .. "#splineTime") or 0)
    spec.vehicleIdsToLoad = {}
    for _, railroadKey in xmlFile:iterator(key .. ".railroadVehicle") do
        local index = xmlFile:getValue(railroadKey .. "#vehicleUniqueId")
        if index ~= nil then
            table.insert(spec.vehicleIdsToLoad, index)
        end
    end
end
function PlaceableTrainSystem:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_trainSystem
    xmlFile:setValue(key .. "#splineTime", SplineUtil.getValidSplineTime(spec.splineTime))
    for k, railroadVehicle in ipairs(spec.railroadVehicles) do
        xmlFile:setValue(string.format("%s.railroadVehicle(%d)", key, k - 1) .. "#vehicleUniqueId", railroadVehicle:getUniqueId())
    end
    for k, railroadVehicle in ipairs(spec.railroadObjects) do
        local railroadKey = string.format("%s.railroadObjects(%d)", key, k - 1)
        if railroadVehicle.saveToXMLFile ~= nil then
            xmlFile:setValue(railroadKey .. "#index", k)
            railroadVehicle.saveToXMLFile(xmlFile, railroadKey, usedModNames)
        end
    end
    xmlFile:setValue(key .. "#isRented", spec.isRented)
    xmlFile:setValue(key .. "#rentFarmId", spec.rentFarmId)
    xmlFile:setValue(key .. "#currentPrice", spec.currentPrice)
end
function PlaceableTrainSystem:onUpdate(dt)
    local spec = self.spec_trainSystem
    if not self.finishedFirstUpdate then
        local textSellQuestion = spec.isRented
        if textSellQuestion then
            textSellQuestion = g_currentMission:getFarmId() == spec.rentFarmId
        end
        self:setIsTrainTabbable(textSellQuestion)
        self.finishedFirstUpdate = true
    end
    if self.isClient then
        spec.splinePositionSpeed = spec.splinePositionSpeed * 0.975 + spec.splinePositionSpeedReal * 0.025
    end
    for _, railroadObject in ipairs(spec.railroadObjects) do
        if railroadObject.update ~= nil then
            railroadObject:update(dt)
        end
    end
    if spec.isRented then
        spec.currentPrice = spec.currentPrice + spec.rentPricePerMS * dt
    end
    if not self.isServer and self.isClient then
        if spec.railroadVehicleIds ~= nil then
            local allVehiclesSynchronized = true
            for railroadObject, id in pairs(spec.railroadVehicleIds) do
                local vehicle = NetworkUtil.getObject(id)
                if vehicle == nil or not vehicle:getIsSynchronized() then
                    allVehiclesSynchronized = false
                end
            end
            if allVehiclesSynchronized then
                spec.rootLocomotive = nil
                for railroadObject, id in pairs(spec.railroadVehicleIds) do
                    local vehicle = NetworkUtil.getObject(id)
                    if vehicle ~= nil then
                        vehicle:setTrainSystem(self)
                        spec.trainLength = spec.trainLength + vehicle:getFrontToBackDistance()
                        spec.trainLengthSplineTime = spec.trainLength / spec.splineLength
                        table.insert(spec.railroadVehicles, railroadObject, vehicle)
                        if spec.rootLocomotive == nil and vehicle.startAutomatedTrainTravel ~= nil then
                            spec.rootLocomotive = vehicle
                        end
                    end
                    spec.railroadVehicleIds[railroadObject] = nil
                end
                if next(spec.railroadVehicleIds) == nil then
                    spec.railroadVehicleIds = nil
                    self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
                end
            end
        end
        spec.networkTimeInterpolator:update(dt)
        local allVehiclesSynchronized = spec.networkTimeInterpolator:getAlpha()
        local splineTime = spec.networkSplineTimeInterpolator:getInterpolatedValue(allVehiclesSynchronized)
        self:updateTrainPositionByLocomotiveSplinePosition((SplineUtil.getValidSplineTime(splineTime)))
    end
    if spec.hasLimitedRange then
        if self.isServer and (spec.sellingStationPlaceable == nil and spec.drivingRangeSellingStationId ~= nil) then
            local allVehiclesSynchronized = g_currentMission.placeableSystem:getPlaceableByUniqueId(spec.drivingRangeSellingStationId)
            if allVehiclesSynchronized == nil then
                Logging.xmlWarning(self.configFileName, "Unable to find selling station placeable with id %q", spec.drivingRangeSellingStationId)
            elseif allVehiclesSynchronized.spec_sellingStation ~= nil then
                spec.sellingStationPlaceable = allVehiclesSynchronized
                spec.sellingStation = allVehiclesSynchronized.spec_sellingStation.sellingStation
                self:raiseDirtyFlags(spec.stationDirtyFlag)
            end
            spec.drivingRangeSellingStationId = nil
        end
        if spec.sellingStationPlaceable == nil and spec.sellingStationPlaceableId ~= nil then
            local allVehiclesSynchronized = NetworkUtil.getObject(spec.sellingStationPlaceableId)
            if allVehiclesSynchronized ~= nil and allVehiclesSynchronized.spec_sellingStation ~= nil then
                spec.sellingStationPlaceable = allVehiclesSynchronized
                spec.sellingStation = allVehiclesSynchronized.spec_sellingStation.sellingStation
            end
        end
        if spec.showDialogDelay > 0 then
            spec.showDialogDelay = spec.showDialogDelay - dt
            if spec.showDialogDelay <= 0 then
                local allVehiclesSynchronized = "UNKNOWN"
                if spec.sellingStationPlaceable ~= nil then
                    allVehiclesSynchronized = spec.sellingStationPlaceable:getName()
                end
                local splineTime = string.format(spec.textDriveInfo, allVehiclesSynchronized)
                local textSellQuestion = string.format(spec.textSellQuestion, allVehiclesSynchronized)
                if spec.showDialog == 2 then
                    YesNoDialog.show(self.onSellGoodsQuestion, self, splineTime .. "\n\n" .. textSellQuestion)
                else
                    InfoDialog.show(splineTime)
                end
                spec.showDialog = 0
            end
        end
    end
    self:updateRailroadVehiclePositions(dt)
    self:raiseActive()
end
function PlaceableTrainSystem:updateRailroadVehiclePositions(_)
    local spec = self.spec_trainSystem
    if spec.lastUpdateLoopIndex < g_updateLoopIndex then
        spec.lastUpdateLoopIndex = g_updateLoopIndex
        for _, railroadVehicle in pairs(spec.railroadVehicles) do
            if railroadVehicle.getLocomotiveSpeed ~= nil then
                local locomotiveSpeed = railroadVehicle:getLocomotiveSpeed()
                local interpDt = g_physicsDt
                if g_server == nil then
                    interpDt = g_physicsDtUnclamped
                end
                if locomotiveSpeed ~= 0 then
                    self:updateTrainPositionByLocomotiveSpeed(interpDt, locomotiveSpeed)
                end
            end
        end
        local maxNumVehicleUpdatesPerFrame = 3
        for railroadVehicle, locomotiveSpeed in pairs(spec.railroadVehicles) do
            if getClipDistance(locomotiveSpeed.rootNode) > locomotiveSpeed.currentUpdateDistance then
                maxNumVehicleUpdatesPerFrame = math.huge
                break
            end
        end
        local numUpdates = 0
        while true do
            local railroadVehicle = spec.railroadVehicles[spec.railroadVehicleUpdateIndex + 1]
            if railroadVehicle == nil then
                break
            end
            local _ = spec.splineTime
            if spec.railroadVehicleUpdateIndex > 0 then
                _ = spec.railroadVehiclesEndTimes[spec.railroadVehicles[spec.railroadVehicleUpdateIndex]]
            end
            local railroadVehicle = railroadVehicle:alignToSplineTime(spec.spline, spec.splineYOffset, _)
            spec.railroadVehiclesEndTimes[railroadVehicle] = railroadVehicle
            spec.railroadVehicleUpdateIndex = (spec.railroadVehicleUpdateIndex + 1) % #spec.railroadVehicles
            numUpdates = numUpdates + 1
            if numUpdates == maxNumVehicleUpdatesPerFrame or numUpdates == #spec.railroadVehicles then
                break
            end
        end
    end
end
function PlaceableTrainSystem:createVehicles()
    local spec = self.spec_trainSystem
    if spec.vehicleIdsToLoad == nil or #spec.vehicleIdsToLoad <= 0 then
        for k, uniqueId in ipairs(spec.vehiclesToLoad) do
            local vehicle = Utils.getFilename(uniqueId, spec.baseDirectory)
            spec.numVehiclesToLoad = spec.numVehiclesToLoad + 1
            local data = VehicleLoadingData.new()
            data:setFilename(vehicle)
            data:setPropertyState(VehiclePropertyState.NONE)
            data:setOwnerFarmId(AccessHandler.EVERYONE)
            data:load(spec.railroadVehicleLoaded, self, {
                ["filename"] = vehicle,
                ["vehicleIndex"] = k
            })
        end
    else
        for k, uniqueId in ipairs(spec.vehicleIdsToLoad) do
            local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(uniqueId)
            if vehicle ~= nil then
                if vehicle.setTrainSystem ~= nil then
                    vehicle:setTrainSystem(self)
                    vehicle.trainVehicleIndex = k
                    table.insert(spec.railroadVehicles, vehicle)
                end
            end
        end
        self:finalizeTrain(false)
    end
    spec.vehiclesToLoad = {}
end
function PlaceableTrainSystem:railroadVehicleLoaded(vehicles, vehicleLoadState, args)
    local spec = self.spec_trainSystem
    if vehicleLoadState == VehicleLoadingState.OK and #vehicles > 0 then
        local vehicle = vehicles[1]
        if not self:getIsBeingDeleted() then
            vehicle:setTrainSystem(self)
            vehicle.trainVehicleIndex = args.vehicleIndex
        end
        table.insert(spec.railroadVehicles, vehicle)
    else
        Logging.warning("(%s) Could not create trainsystem vehicle!", args.filename)
    end
    spec.numVehiclesToLoad = spec.numVehiclesToLoad - 1
    if spec.numVehiclesToLoad == 0 and #spec.vehiclesToLoad == 0 then
        self:finalizeTrain(true)
    end
end
function PlaceableTrainSystem:finalizeTrain(attachVehicles)
    if not self:getIsBeingDeleted() then
        local spec = self.spec_trainSystem
        table.sort(spec.railroadVehicles, function(a, b)
            return a.trainVehicleIndex < b.trainVehicleIndex
        end)
        local lastVehicle = nil
        spec.rootLocomotive = nil
        for _, railroadVehicle in ipairs(spec.railroadVehicles) do
            if not railroadVehicle:getIsBeingDeleted() then
                railroadVehicle:addDeleteListener(self)
                if spec.rootLocomotive == nil and railroadVehicle.startAutomatedTrainTravel ~= nil then
                    spec.rootLocomotive = railroadVehicle
                end
                if attachVehicles and lastVehicle ~= nil then
                    lastVehicle:attachImplement(railroadVehicle, 1, 1, true)
                end
                lastVehicle = railroadVehicle
            end
        end
        self:updateTrainLength(spec.startSplineTime)
        self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
    end
end
function PlaceableTrainSystem:setIsTrainTabbable(isTabbable)
    local spec = self.spec_trainSystem
    if isTabbable then
        isTabbable = g_gameSettings:getValue(GameSettings.SETTING.IS_TRAIN_TABBABLE)
    end
    if spec.hasLimitedRange then
        if isTabbable then
            isTabbable = spec.lastIsInDriveableRange
        end
    end
    for _, railroadVehicle in ipairs(spec.railroadVehicles) do
        if railroadVehicle.setIsTabbable ~= nil then
            railroadVehicle:setIsTabbable(isTabbable)
        end
    end
end
function PlaceableTrainSystem:getIsTrainInDriveableRange()
    return self.spec_trainSystem.lastIsInDriveableRange
end
function PlaceableTrainSystem:getSplineTime()
    return self.spec_trainSystem.splineTime
end
function PlaceableTrainSystem:setSplineTime(startTime, endTime)
    local spec = self.spec_trainSystem
    local delta = SplineUtil.getValidSplineTime(startTime)
    local delta = SplineUtil.getValidSplineTime(endTime)
    if delta ~= spec.splineTime then
        if spec.hasLimitedRange then
            self:updateDriveableState(delta)
        end
        for _, listener in ipairs(spec.splinePositionUpdateListener) do
            listener:onSplinePositionTimeUpdate(delta, delta)
        end
        local delta = delta - spec.splineTime
        spec.splineTime = delta
        spec.splineEndTime = delta
        local interpDt, threshold, _ = getSplinePosition(spec.spline, spec.splineTime)
        spec.x = interpDt
        spec.y = threshold
        spec.z = _
        local interpDt = g_physicsDt
        if g_server == nil then
            interpDt = g_physicsDtUnclamped
        end
        spec.splinePositionSpeedReal = delta * spec.splineLength * (1000 / interpDt)
        if self.isServer then
            spec.splinePositionSpeed = spec.splinePositionSpeedReal
        end
        if spec.firstUpdate then
            spec.splinePositionSpeedReal = 0
            spec.splinePositionSpeed = 0
            spec.firstUpdate = false
        end
        for _, railroadVehicle in ipairs(spec.railroadVehicles) do
            railroadVehicle:setSplineSpeed(spec.splinePositionSpeed, spec.splinePositionSpeedReal)
        end
        if self.isServer then
            if 0.02 / spec.splineLength < math.abs(spec.splineTime - spec.splineTimeSent) then
                spec.splineTimeSent = spec.splineTime
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
    end
end
function PlaceableTrainSystem:getTrainPosition()
    local spec = self.spec_trainSystem
    return spec.x, spec.y, spec.z
end
function PlaceableTrainSystem:addSplinePositionUpdateListener(listener)
    if listener ~= nil then
        table.addElement(self.spec_trainSystem.splinePositionUpdateListener, listener)
    end
end
function PlaceableTrainSystem:removeSplinePositionUpdateListener(listener)
    if listener ~= nil then
        table.removeElement(self.spec_trainSystem.splinePositionUpdateListener, listener)
    end
end
function PlaceableTrainSystem:updateTrainPositionByLocomotiveSpeed(dt, speed)
    local spec = self.spec_trainSystem
    local splineTime = self:getSplineTime() + speed * (dt / 1000) / spec.splineLength
    self:setSplineTime(splineTime, splineTime - spec.trainLengthSplineTime)
end
function PlaceableTrainSystem:updateTrainPositionByLocomotiveSplinePosition(splineTime)
    self:setSplineTime(splineTime, splineTime - self.spec_trainSystem.trainLengthSplineTime)
end
function PlaceableTrainSystem:updateTrainLength(splinePosition)
    local spec = self.spec_trainSystem
    for _, railroadVehicle in ipairs(spec.railroadVehicles) do
        spec.trainLength = spec.trainLength + railroadVehicle:getFrontToBackDistance()
    end
    spec.trainLengthSplineTime = spec.trainLength / spec.splineLength
    self:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
end
function PlaceableTrainSystem:toggleRent(farmId, position)
    local spec = self.spec_trainSystem
    if spec.isRented then
        if spec.rentFarmId == farmId then
            self:returnRailroad()
            return
        end
    else
        self:rentRailroad(farmId, position, false)
    end
end
function PlaceableTrainSystem:rentRailroad(farmId, position, noEventSend)
    local spec = self.spec_trainSystem
    if spec.rootLocomotive ~= nil then
        spec.isRented = true
        spec.rentFarmId = farmId
        spec.lastRentFarmId = farmId
        spec.rootLocomotive:setRequestedSplinePosition(position)
        for _, railroadVehicle in ipairs(spec.railroadVehicles) do
            railroadVehicle:setOwnerFarmId(spec.rentFarmId, true)
        end
        self:setIsTrainTabbable(g_currentMission:getFarmId() == farmId)
        PlaceableTrainSystemRentEvent.sendEvent(self, true, farmId, position, noEventSend)
    end
end
function PlaceableTrainSystem:returnRailroad(noEventSend)
    local spec = self.spec_trainSystem
    spec.isRented = false
    if self.isServer then
        if spec.currentPrice > 0 then
            g_currentMission:addMoney(-spec.currentPrice, spec.rentFarmId, MoneyType.LEASING_COSTS, true)
            g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS, nil, false, spec.rentFarmId)
            spec.currentPrice = 0
        end
        spec.rootLocomotive:startAutomatedTrainTravel()
    end
    spec.rentFarmId = FarmManager.SPECTATOR_FARM_ID
    for _, railroadVehicle in ipairs(spec.railroadVehicles) do
        railroadVehicle:setOwnerFarmId(spec.rentFarmId, true)
    end
    self:setIsTrainTabbable(false)
    PlaceableTrainSystemRentEvent.sendEvent(self, false, nil, nil, noEventSend)
end
function PlaceableTrainSystem:onDayChanged()
    if self.isServer then
        local spec = self.spec_trainSystem
        if spec.currentPrice > 0 then
            g_currentMission:addMoney(-spec.currentPrice, spec.rentFarmId, MoneyType.LEASING_COSTS, true)
            g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS, nil, false, spec.rentFarmId)
            spec.currentPrice = 0
        end
    end
end
function PlaceableTrainSystem:getIsRented()
    return self.spec_trainSystem.isRented
end
function PlaceableTrainSystem:getCanBeRented(farmId)
    local spec = self.spec_trainSystem
    return (not spec.isRented or spec.rentFarmId == farmId) and true or false
end
function PlaceableTrainSystem:onDeleteObject(object)
    local spec = self.spec_trainSystem
    if table.removeElement(spec.railroadVehicles, object) then
        self:updateTrainLength(spec.splineTime)
    end
end
function PlaceableTrainSystem:getSplineLength()
    return self.spec_trainSystem.splineLength
end
function PlaceableTrainSystem:getElectricitySpline()
    return self.spec_trainSystem.electricitySpline
end
function PlaceableTrainSystem:getElectricitySplineLength()
    return self.spec_trainSystem.electricitySplineLength or 0
end
function PlaceableTrainSystem:getNeedDayChanged(superFunc)
    return true
end
function PlaceableTrainSystem:getLengthSplineTime()
    return self.spec_trainSystem.trainLengthSplineTime
end
function PlaceableTrainSystem:getSpline()
    return self.spec_trainSystem.spline
end
function PlaceableTrainSystem:updateDriveableState(newSplineTime)
    local spec = self.spec_trainSystem
    local isInDriveableRange = false
    if newSplineTime % 1 >= spec.splineDriveRange[1] then
        isInDriveableRange = newSplineTime % 1 <= spec.splineDriveRange[2]
    end
    if isInDriveableRange ~= spec.lastIsInDriveableRange then
        spec.lastIsInDriveableRange = isInDriveableRange
        if isInDriveableRange then
            if self.isServer then
                for _, railroadVehicle in ipairs(spec.railroadVehicles) do
                    local locomotiveSpec = railroadVehicle.spec_locomotive
                    if locomotiveSpec ~= nil then
                        if railroadVehicle:getIsReadyForAutomatedTrainTravel() then
                            if locomotiveSpec.sellingDirection ~= nil and locomotiveSpec.sellingDirection < 0 then
                                locomotiveSpec.sellingDirection = 1
                                railroadVehicle:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
                            end
                        elseif locomotiveSpec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
                            railroadVehicle:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
                            locomotiveSpec.sellingDirection = 1
                        end
                    end
                end
            end
        else
            for _, railroadVehicle in ipairs(spec.railroadVehicles) do
                if self.isClient and (railroadVehicle.getIsEntered ~= nil and railroadVehicle:getIsEntered()) then
                    g_localPlayer:leaveVehicle()
                    spec.showDialogDelay = 100
                    spec.showDialog = 1
                    if self:gsIsTrainFilled() then
                        spec.showDialog = 2
                    end
                end
                if self.isServer then
                    local locomotiveSpec = railroadVehicle.spec_locomotive
                    if locomotiveSpec ~= nil and (locomotiveSpec.state ~= Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE and (locomotiveSpec.state ~= Locomotive.STATE_REQUESTED_POSITION and locomotiveSpec.state ~= Locomotive.STATE_REQUESTED_POSITION_BRAKING)) then
                        railroadVehicle:setLocomotiveState(Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE)
                        if not self:gsIsTrainFilled() and spec.isRented then
                            self:returnRailroad()
                        end
                        if spec.splineTime < newSplineTime then
                            locomotiveSpec.sellingDirection = 1
                        else
                            locomotiveSpec.sellingDirection = -1
                        end
                    end
                end
            end
        end
        self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
    end
end
function PlaceableTrainSystem:gsIsTrainFilled()
    for _, railroadVehicle2 in ipairs(self.spec_trainSystem.railroadVehicles) do
        if railroadVehicle2.getFillUnits ~= nil then
            local fillUnits = railroadVehicle2:getFillUnits()
            for fillUnitIndex, fillUnit in ipairs(fillUnits) do
                if fillUnit.fillLevel > 0 then
                    return true
                end
            end
        end
    end
    return false
end
function PlaceableTrainSystem:onSellGoodsQuestion(yes)
    if yes then
        g_client:getServerConnection():sendEvent(PlaceableTrainSystemSellEvent.new(self))
    end
end
function PlaceableTrainSystem:sellGoods()
    local spec = self.spec_trainSystem
    if spec.sellingStation ~= nil and spec.rentFarmId ~= 0 then
        local soldDelta = 0
        for _, railroadVehicle in ipairs(spec.railroadVehicles) do
            if railroadVehicle.getFillUnits ~= nil then
                local fillUnits = railroadVehicle:getFillUnits()
                for fillUnitIndex, fillUnit in ipairs(fillUnits) do
                    local delta = spec.sellingStation:addFillLevelFromTool(spec.rentFarmId, fillUnit.fillLevel, fillUnit.fillType, nil, ToolType.UNDEFINED)
                    railroadVehicle:addFillUnitFillLevel(railroadVehicle:getOwnerFarmId(), fillUnitIndex, -delta, fillUnit.fillType, ToolType.UNDEFINED, nil)
                end
            end
        end
        if soldDelta > 0 and spec.isRented then
            self:returnRailroad()
        end
    end
end