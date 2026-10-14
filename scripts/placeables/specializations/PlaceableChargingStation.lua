PlaceableChargingStation = {}
function PlaceableChargingStation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableBuyingStation, specializations)
end
function PlaceableChargingStation.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getIsCharging", PlaceableChargingStation.getIsCharging)
    SpecializationUtil.registerFunction(placeableType, "getChargeState", PlaceableChargingStation.getChargeState)
end
function PlaceableChargingStation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableChargingStation)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableChargingStation)
end
function PlaceableChargingStation.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("BuyingStation")
    BuyingStation.registerXMLPaths(schema, basePath .. ".buyingStation")
    schema:register(XMLValueType.FLOAT, basePath .. ".chargingStation.chargeIndicator#intensity", "Light intensity", 20)
    schema:register(XMLValueType.FLOAT, basePath .. ".chargingStation.chargeIndicator#blinkSpeed", "Blinking speed", 5)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".chargingStation.chargeIndicator#node", "Charge indicator node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".chargingStation.chargeIndicator#light", "Charge indicator light node")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".chargingStation.chargeIndicator#colorFull", "Color while battery is charged", "0 1 0 1")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".chargingStation.chargeIndicator#colorEmpty", "Color while battery is empty", "1 1 0 1")
    schema:register(XMLValueType.FLOAT, basePath .. ".chargingStation#interactionRadius", "While player is in this range the battery state is displayed", 5)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".chargingStation.sounds", "fill")
    schema:setXMLSpecializationType()
end
function PlaceableChargingStation:onLoad(_)
    local spec = self.spec_chargingStation
    spec.chargeIndicatorIntensity = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#intensity", 20)
    spec.chargeIndicatorBlinkSpeed = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#blinkSpeed", 5)
    spec.chargeIndicatorNode = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#node", nil, self.components, self.i3dMappings)
    if spec.chargeIndicatorNode ~= nil then
        setShaderParameter(spec.chargeIndicatorNode, "lightControl", spec.chargeIndicatorIntensity, 0, 0, 0, false)
        setShaderParameter(spec.chargeIndicatorNode, "emitColor", 1, 1, 0, 0, false)
    end
    spec.chargeIndicatorLight = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#light", nil, self.components, self.i3dMappings)
    if spec.chargeIndicatorLight then
        setLightColor(spec.chargeIndicatorLight, 0, 0, 0)
    end
    spec.chargeIndicatorColorFull = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#colorFull", "0 1 0 1", true)
    spec.chargeIndicatorColorEmpty = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#colorEmpty", "1 1 0 1", true)
    spec.chargeIndicatorLightColor = spec.chargeIndicatorColorFull
    spec.interactionRadius = self.xmlFile:getValue("placeable.chargingStation#interactionRadius", 5)
    spec.loadTrigger = nil
    spec.buyingStation = self:getBuyingStation()
    if spec.buyingStation ~= nil then
        local j = 1
        for j = j, #spec.buyingStation.loadTriggers do
            local loadTrigger = spec.buyingStation.loadTriggers[j]
            spec.loadTrigger = loadTrigger
            spec.fillSample = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.chargingStation.sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
            if spec.fillSample ~= nil and loadTrigger.samples.load == nil then
                loadTrigger.samples.load = spec.fillSample
            end
        end
    end
end
function PlaceableChargingStation:getIsCharging()
    local spec = self.spec_chargingStation
    if spec.loadTrigger == nil then
        return false
    else
        return spec.loadTrigger.isLoading
    end
end
function PlaceableChargingStation:getChargeState()
    local spec = self.spec_chargingStation
    if spec.loadTrigger ~= nil then
        local index = next(spec.loadTrigger.fillableObjects)
        if index ~= nil then
            local vehicle = spec.loadTrigger.fillableObjects[index].object
            if vehicle.getConsumerFillUnitIndex ~= nil then
                local fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE)
                if fillUnitIndex ~= nil then
                    return vehicle:getFillUnitFillLevel(fillUnitIndex), vehicle:getFillUnitCapacity(fillUnitIndex)
                end
            end
        end
    end
    return 0, 1
end
function PlaceableChargingStation:onUpdate(_)
    local spec = self.spec_chargingStation
    if spec.loadTrigger ~= nil then
        local isActive = next(spec.loadTrigger.fillableObjects) ~= nil
        if spec.chargeIndicatorNode ~= nil then
            if isActive then
                local color = spec.chargeIndicatorColorEmpty
                local fillLevel, capacity = self:getChargeState()
                if fillLevel / capacity > 0.95 then
                    color = spec.chargeIndicatorColorFull
                end
                setShaderParameter(spec.chargeIndicatorNode, "colorScale", color[1], color[2], color[3], color[4], false)
                spec.chargeIndicatorLightColor = color
            end
            local color = spec.loadTrigger.isLoading and spec.chargeIndicatorBlinkSpeed or 0
            setShaderParameter(spec.chargeIndicatorNode, "blinkSimple", color, 0, 0, 0, false)
            setShaderParameter(spec.chargeIndicatorNode, "lightControl", isActive and spec.chargeIndicatorIntensity or 0, 0, 0, 0, false)
            if spec.chargeIndicatorLight ~= nil then
                local fillLevel = 0
                if isActive then
                    local capacity, blinkTimeOffset, _, _ = getShaderParameter(spec.chargeIndicatorNode, "blinkSimple")
                    local object = 4 * math.abs(math.fmod(capacity * getShaderTimeSec() + blinkTimeOffset, 1) - 0.5) - 0.8
                    fillLevel = math.clamp(object, 0, 1)
                end
                setLightColor(spec.chargeIndicatorLight, spec.chargeIndicatorLightColor[1] * fillLevel, spec.chargeIndicatorLightColor[2] * fillLevel, spec.chargeIndicatorLightColor[3] * fillLevel)
            end
        end
        if spec.loadTrigger.isLoading then
            local color = false
            local fillLevel = g_localPlayer
            if fillLevel == nil or fillLevel:getIsInVehicle() then
                local capacity = fillLevel:getCurrentVehicle()
                if capacity ~= nil then
                    for _, object in pairs(spec.loadTrigger.fillableObjects) do
                        if object.object == capacity then
                            color = true
                        end
                    end
                end
            elseif calcDistanceFrom(fillLevel.rootNode, self.rootNode) < spec.interactionRadius then
                color = true
            end
            if color then
                local capacity, blinkTimeOffset = self:getChargeState()
                local _ = (blinkTimeOffset - capacity) / (spec.loadTrigger.fillLitersPerMS * 1000)
                if _ >= 1 then
                    local chargingInfoText = string.namedFormat(g_i18n:getText("info_chargeTime"), "hours", hours, "minutes", object - math.floor(math.floor(_ / 60) / 60) * 60, "percentage", capacity / blinkTimeOffset * 100)
                    g_currentMission:addExtraPrintText(chargingInfoText)
                end
            end
        end
        if isActive then
            self:raiseActive()
        end
    end
end