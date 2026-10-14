Washable = {}
Washable.SEND_NUM_BITS = 6
Washable.SEND_MAX_VALUE = 2 ^ Washable.SEND_NUM_BITS - 1
Washable.SEND_THRESHOLD = 1 / Washable.SEND_MAX_VALUE
Washable.SEND_NUM_BITS_WETNESS = 4
Washable.SEND_MAX_VALUE_WETNESS = 2 ^ Washable.SEND_NUM_BITS_WETNESS - 1
Washable.SEND_THRESHOLD_WETNESS = 1 / Washable.SEND_MAX_VALUE_WETNESS
Washable.WASHTYPE_HIGH_PRESSURE_WASHER = 1
Washable.WASHTYPE_RAIN = 2
Washable.WASHTYPE_TRIGGER = 3
Washable.SHADER_PARAMETERS = { "scratches_dirt_snow_wetness", "mudAmount" }
function Washable.prerequisitesPresent(specializations)
    return true
end
function Washable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Washable")
    schema:register(XMLValueType.FLOAT, "vehicle.washable#dirtDuration", "Duration until fully dirty (minutes)", 90)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#washDuration", "Duration until fully clean (minutes)", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#rainWashDuration", "Duration until fully clean when it rains (minutes)", 10)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#wetDuration", "Duration until fully wet (ingame minutes)", 10)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#dryDuration", "Duration until the vehicle is fully dry again (ingame minutes)", 120)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#workMultiplier", "Multiplier while working", 4)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#fieldMultiplier", "Multiplier while on field", 2)
    schema:register(XMLValueType.FLOAT, "vehicle.washable#wetMultiplier", "Multiplier while on it\'s wet", 5)
    schema:register(XMLValueType.STRING, "vehicle.washable#blockedWashTypes", "Block specific ways to clean vehicle (HIGH_PRESSURE_WASHER, RAIN, TRIGGER)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.washable.wetnessIgnoreNode(?)#node", "Node, including it\'s children will never get wet")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#amount", "Dirt amount")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#snowScale", "Snow scale")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#wetness", "Wetness")
end
function Washable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "cleanVehicle", Washable.cleanVehicle)
    SpecializationUtil.registerFunction(vehicleType, "updateDirtAmount", Washable.updateDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "addDirtAmount", Washable.addDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "setDirtAmount", Washable.setDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDirtAmount", Washable.getDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "setNodeDirtAmount", Washable.setNodeDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "getNodeDirtAmount", Washable.getNodeDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "setNodeDirtColor", Washable.setNodeDirtColor)
    SpecializationUtil.registerFunction(vehicleType, "updateWetness", Washable.updateWetness)
    SpecializationUtil.registerFunction(vehicleType, "getIsWet", Washable.getIsWet)
    SpecializationUtil.registerFunction(vehicleType, "addWetnessAmount", Washable.addWetnessAmount)
    SpecializationUtil.registerFunction(vehicleType, "setNodeWetness", Washable.setNodeWetness)
    SpecializationUtil.registerFunction(vehicleType, "addAllSubWashableNodes", Washable.addAllSubWashableNodes)
    SpecializationUtil.registerFunction(vehicleType, "addWashableNodes", Washable.addWashableNodes)
    SpecializationUtil.registerFunction(vehicleType, "addWashableNode", Washable.addWashableNode)
    SpecializationUtil.registerFunction(vehicleType, "validateWashableNode", Washable.validateWashableNode)
    SpecializationUtil.registerFunction(vehicleType, "addToGlobalWashableNode", Washable.addToGlobalWashableNode)
    SpecializationUtil.registerFunction(vehicleType, "getWashableNodeByCustomIndex", Washable.getWashableNodeByCustomIndex)
    SpecializationUtil.registerFunction(vehicleType, "addToLocalWashableNode", Washable.addToLocalWashableNode)
    SpecializationUtil.registerFunction(vehicleType, "removeAllSubWashableNodes", Washable.removeAllSubWashableNodes)
    SpecializationUtil.registerFunction(vehicleType, "removeWashableNode", Washable.removeWashableNode)
    SpecializationUtil.registerFunction(vehicleType, "getDirtMultiplier", Washable.getDirtMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "getWorkDirtMultiplier", Washable.getWorkDirtMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "getWashDuration", Washable.getWashDuration)
    SpecializationUtil.registerFunction(vehicleType, "getAllowsWashingByType", Washable.getAllowsWashingByType)
end
function Washable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Washable)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Washable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Washable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Washable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Washable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Washable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Washable)
end
function Washable:onLoad(_)
    local spec = self.spec_washable
    spec.wetnessIgnoreNodes = {}
    for _, key in self.xmlFile:iterator("vehicle.washable.wetnessIgnoreNode") do
        local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid node for wetnessIgnoreNode \'%s\'", key)
        else
            spec.wetnessIgnoreNodes[node] = true
        end
    end
    spec.washableNodes = {}
    spec.washableNodesByIndex = {}
    self:addToLocalWashableNode(nil, Washable.updateDirtAmount, nil, nil)
    spec.globalWashableNode = spec.washableNodes[1]
    spec.dirtDuration = self.xmlFile:getValue("vehicle.washable#dirtDuration", 90) * 60 * 1000
    if spec.dirtDuration ~= 0 then
        spec.dirtDuration = 1 / spec.dirtDuration
    end
    local blockedWashTypes = self.xmlFile:getValue("vehicle.washable#washDuration", 1) * 60 * 1000
    spec.washDuration = math.max(blockedWashTypes, 0.00001)
    local blockedWashTypes = self.xmlFile:getValue("vehicle.washable#rainWashDuration", 10) * 60 * 1000
    spec.rainWashDuration = math.max(blockedWashTypes, 0.00001)
    spec.wetDuration = self.xmlFile:getValue("vehicle.washable#wetDuration", 10) / 60 / 1000
    spec.dryDuration = 1 / math.max(self.xmlFile:getValue("vehicle.washable#dryDuration", 120) * 60 * 1000, 0.0001)
    spec.workMultiplier = self.xmlFile:getValue("vehicle.washable#workMultiplier", 4)
    spec.fieldMultiplier = self.xmlFile:getValue("vehicle.washable#fieldMultiplier", 2)
    spec.wetMultiplier = self.xmlFile:getValue("vehicle.washable#wetMultiplier", 5)
    spec.blockedWashTypes = {}
    local blockedWashTypesStr = self.xmlFile:getValue("vehicle.washable#blockedWashTypes")
    if blockedWashTypesStr ~= nil then
        local blockedWashTypes = blockedWashTypesStr:split(" ")
        for node, typeStr in pairs(blockedWashTypes) do
            local typeStr = "WASHTYPE_" .. typeStr
            if Washable[typeStr] == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wash type \'%s\' in \'%s\'", typeStr, "vehicle.washable#blockedWashTypes")
            else
                spec.blockedWashTypes[Washable[typeStr]] = true
            end
        end
    end
    spec.lastDirtMultiplier = 0
    spec.dirtyFlag = self:getNextDirtyFlag()
    if self.propertyState == VehiclePropertyState.SHOP_CONFIG then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", Washable)
    end
end
function Washable:onLoadFinished(savegame)
    for _, component in pairs(self.components) do
        self:addAllSubWashableNodes(component.node)
    end
    if savegame == nil or Washable.getIntervalMultiplier() == 0 then
        local i = 1
        for i = i, #self.spec_washable.washableNodes do
            self:setNodeDirtAmount(spec.washableNodes[i], 0, true)
        end
    else
        local i = 1
        for i = i, #spec.washableNodes do
            local _ = spec.washableNodes[i]
            local component = string.format("%s.washable.dirtNode(%d)", savegame.key, i - 1)
            self:setNodeDirtAmount(_, savegame.xmlFile:getValue(component .. "#amount", 0), true)
            self:setNodeWetness(_, savegame.xmlFile:getValue(component .. "#wetness", 0), true)
            if _.loadFromSavegameFunc ~= nil then
                _.loadFromSavegameFunc(savegame.xmlFile, component)
            end
        end
    end
end
function Washable:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        local nodeKey = string.format("%s.dirtNode(%d)", key, i - 1)
        xmlFile:setValue(nodeKey .. "#amount", nodeData.dirtAmount)
        xmlFile:setValue(nodeKey .. "#wetness", nodeData.wetness)
        if nodeData.saveToSavegameFunc ~= nil then
            nodeData.saveToSavegameFunc(xmlFile, nodeKey)
        end
    end
end
function Washable:onReadStream(streamId, connection)
    Washable.readWashableNodeData(self, streamId, connection)
end
function Washable:onWriteStream(streamId, connection)
    Washable.writeWashableNodeData(self, streamId, connection)
end
function Washable:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and (self.spec_washable.washableNodes ~= nil and streamReadBool(streamId)) then
        Washable.readWashableNodeData(self, streamId, connection)
    end
end
function Washable:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_washable.dirtyFlag) ~= 0) then
            Washable.writeWashableNodeData(self, streamId, connection)
        end
    end
end
function Washable:readWashableNodeData(streamId, _)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        self:setNodeDirtAmount(nodeData, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, true)
        self:setNodeWetness(nodeData, streamReadUIntN(streamId, Washable.SEND_NUM_BITS_WETNESS) / Washable.SEND_MAX_VALUE_WETNESS, true)
        if streamReadBool(streamId) then
            self:setNodeDirtColor(nodeData, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE, true)
        end
    end
end
function Washable:writeWashableNodeData(streamId, _)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        streamWriteUIntN(streamId, math.floor(nodeData.dirtAmount * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
        streamWriteUIntN(streamId, math.floor(nodeData.wetness * Washable.SEND_MAX_VALUE_WETNESS + 0.5), Washable.SEND_NUM_BITS_WETNESS)
        streamWriteBool(streamId, nodeData.colorChanged)
        if nodeData.colorChanged then
            streamWriteUIntN(streamId, math.floor(nodeData.color[1] * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
            streamWriteUIntN(streamId, math.floor(nodeData.color[2] * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
            streamWriteUIntN(streamId, math.floor(nodeData.color[3] * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
            nodeData.colorChanged = false
        end
    end
end
function Washable:onUpdateTick(dt, _, _, _)
    if self.isServer then
        local spec = self.spec_washable
        spec.lastDirtMultiplier = self:getDirtMultiplier() * Washable.getIntervalMultiplier() * Platform.gameplay.dirtDurationScale
        local allowsWashingByRain = self:getAllowsWashingByType(Washable.WASHTYPE_RAIN)
        local rainScale = 0
        local timeSinceLastRain = 0
        local temperature = 0
        if allowsWashingByRain then
            local weather = g_currentMission.environment.weather
            rainScale = weather:getRainFallScale()
            timeSinceLastRain = weather:getTimeSinceLastRain()
            temperature = weather:getCurrentTemperature()
        end
        local i = 1
        local weather = #spec.washableNodes
        for i = i, weather do
            local nodeData = spec.washableNodes[i]
            local changeDirt, changeWetness = nodeData.updateFunc(self, nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
            if changeDirt ~= 0 then
                self:setNodeDirtAmount(nodeData, nodeData.dirtAmount + changeDirt)
            end
            if changeWetness ~= 0 then
                self:setNodeWetness(nodeData, nodeData.wetness + changeWetness)
            end
        end
    end
end
function Washable:cleanVehicle(amount)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        local nodeAmount = amount * (nodeData.cleaningMultiplier or 1)
        self:setNodeDirtAmount(nodeData, nodeData.dirtAmount - nodeAmount, true)
        self:setNodeWetness(nodeData, nodeData.wetness + nodeAmount * 5, true)
    end
end
function Washable:updateDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
    local spec = self.spec_washable
    local changeDirt = 0
    local dirtMultiplier = spec.lastDirtMultiplier
    if allowsWashingByRain and (rainScale > 0.1 and (timeSinceLastRain < 30 and (temperature > 0 and (nodeData.dirtAmount > 0.5 and (not self:getIsOnField() or self:getLastSpeed() < 1))))) then
        changeDirt = -(dt / spec.rainWashDuration)
    end
    if temperature > 0 and (rainScale > 0.1 and timeSinceLastRain < 30) then
    end
    if dirtMultiplier ~= 0 then
        changeDirt = dt * spec.dirtDuration * dirtMultiplier
    end
    return changeDirt, 0
end
function Washable:addDirtAmount(dirtAmount, force)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        self:setNodeDirtAmount(nodeData, nodeData.dirtAmount + dirtAmount, force)
    end
end
function Washable:setDirtAmount(dirtAmount)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        if nodeData.wheelDirtNode == nil then
            self:setNodeDirtAmount(nodeData, dirtAmount, true)
        else
            self:setNodeDirtAmount(nodeData, (dirtAmount - 0.75) / 0.25, true)
        end
    end
end
function Washable:getDirtAmount()
    local spec = self.spec_washable
    return #spec.washableNodes <= 0 and 0 or spec.washableNodes[1].dirtAmount
end
function Washable:setNodeDirtAmount(nodeData, dirtAmount, force)
    nodeData.dirtAmount = math.clamp(dirtAmount, 0, 1)
    if math.abs(nodeData.dirtAmountSent - nodeData.dirtAmount) > Washable.SEND_THRESHOLD or (force or nodeData.dirtAmount == 0 and nodeData.dirtAmountSent ~= 0) then
        for node, _ in pairs(nodeData.nodes) do
            setShaderParameter(node, "scratches_dirt_snow_wetness", nil, nodeData.dirtAmount, nil, nil, false)
        end
        if nodeData.wheelDirtNode == nil then
            for node, _ in pairs(nodeData.mudNodes) do
                g_animationManager:setPrevShaderParameter(node, "mudAmount", (nodeData.dirtAmount - 0.75) / 0.25, 0, 0, 0, false, "prevMudAmount")
            end
        else
            for node, _ in pairs(nodeData.mudNodes) do
                g_animationManager:setPrevShaderParameter(node, "mudAmount", nodeData.dirtAmount, 0, 0, 0, false, "prevMudAmount")
            end
        end
        if self.isServer then
            self:raiseDirtyFlags(self.spec_washable.dirtyFlag)
            nodeData.dirtAmountSent = nodeData.dirtAmount
        end
    end
end
function Washable.getNodeDirtAmount(_, nodeData)
    return nodeData.dirtAmount
end
function Washable:setNodeDirtColor(nodeData, r, g, b, force)
    if math.abs(r - nodeData.color[1]) <= Washable.SEND_THRESHOLD then
        if math.abs(g - nodeData.color[2]) <= Washable.SEND_THRESHOLD then
            if math.abs(b - nodeData.color[3]) <= Washable.SEND_THRESHOLD and not force then
                ::l5::
                return
            end
        end
    end
    for node, _ in pairs(nodeData.nodes) do
        setShaderParameter(node, "dirtColor", r, g, b, nil, false)
    end
    for node, _ in pairs(nodeData.mudNodes) do
        setShaderParameter(node, "dirtColor", r, g, b, nil, false)
    end
    nodeData.color[1] = r
    nodeData.color[2] = g
    nodeData.color[3] = b
    if self.isServer then
        self:raiseDirtyFlags(self.spec_washable.dirtyFlag)
        nodeData.colorChanged = true
    end
    goto l5
end
function Washable:updateWetness(isRaining, dt)
    local spec = self.spec_washable
    local changeWetness = nil
    if isRaining then
        changeWetness = dt * spec.wetDuration * (1 + math.min(self.lastSpeed * 3600 / 10, 1))
    end
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        if not isRaining then
            changeWetness = -dt * spec.dryDuration * ((1 - nodeData.dirtAmount) * 0.5 + 0.5) * (1 + math.min(self.lastSpeed * 3600 / 10, 1))
        end
        self:setNodeWetness(nodeData, nodeData.wetness + changeWetness)
    end
end
function Washable:getIsWet()
    for _, nodeData in pairs(self.spec_washable.washableNodes) do
        if nodeData.wetness > 0 then
            return true
        end
    end
    return false
end
function Washable:addWetnessAmount(amount)
    local spec = self.spec_washable
    local i = 1
    for i = i, #spec.washableNodes do
        local nodeData = spec.washableNodes[i]
        self:setNodeWetness(nodeData, nodeData.wetness + amount)
    end
end
function Washable:setNodeWetness(nodeData, wetness, force)
    nodeData.wetness = math.clamp(wetness, 0, 1)
    if math.abs(nodeData.wetnessSent - nodeData.wetness) > Washable.SEND_THRESHOLD_WETNESS or force then
        for node, useWetness in pairs(nodeData.nodes) do
            if useWetness then
                setShaderParameter(node, "scratches_dirt_snow_wetness", nil, nil, nil, nodeData.wetness, false)
            end
        end
        for node, useWetness in pairs(nodeData.mudNodes) do
            if useWetness then
                setShaderParameter(node, "wetness", nodeData.wetness, nil, nil, nil, false)
            end
        end
        if self.isServer then
            self:raiseDirtyFlags(self.spec_washable.dirtyFlag)
            nodeData.wetnessSent = nodeData.wetness
        end
    end
end
function Washable:addAllSubWashableNodes(rootNode)
    if rootNode ~= nil then
        I3DUtil.iterateShaderParametersNodesRecursively(rootNode, Washable.SHADER_PARAMETERS, self.addWashableNode, self)
    end
    self:addDirtAmount(0, true)
end
function Washable:addWashableNodes(nodes)
    for _, node in ipairs(nodes) do
        self:addWashableNode(node)
    end
end
function Washable:addWashableNode(node)
    local isGlobal, updateFunc, customIndex, extraParams = self:validateWashableNode(node)
    if isGlobal then
        self:addToGlobalWashableNode(node)
    elseif updateFunc ~= nil then
        self:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
    end
end
function Washable:validateWashableNode(node)
    return true, nil
end
function Washable:addToGlobalWashableNode(node)
    local spec = self.spec_washable
    if spec.washableNodes[1] ~= nil then
        local useWetness = true
        if next(spec.wetnessIgnoreNodes) ~= nil then
            while true do
                if node == 0 then
                    break
                end
                if spec.wetnessIgnoreNodes[node] == true then
                    useWetness = false
                    break
                end
                node = getParent(node)
            end
        end
        if getHasShaderParameter(node, "scratches_dirt_snow_wetness") then
            spec.washableNodes[1].nodes[node] = useWetness
            return
        end
        spec.washableNodes[1].mudNodes[node] = useWetness
    end
end
function Washable:getWashableNodeByCustomIndex(customIndex)
    return self.spec_washable.washableNodesByIndex[customIndex]
end
function Washable:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
    local spec = self.spec_washable
    local useWetness = true
    if node ~= nil and next(spec.wetnessIgnoreNodes) ~= nil then
        while true do
            if node == 0 then
                break
            end
            if spec.wetnessIgnoreNodes[node] == true then
                useWetness = false
                break
            end
            node = getParent(node)
        end
    end
    local nodeToCheck = {}
    if customIndex ~= nil then
        if spec.washableNodesByIndex[customIndex] ~= nil then
            if getHasShaderParameter(node, "scratches_dirt_snow_wetness") then
                spec.washableNodesByIndex[customIndex].nodes[node] = useWetness
            else
                spec.washableNodesByIndex[customIndex].mudNodes[node] = useWetness
            end
        end
        spec.washableNodesByIndex[customIndex] = nodeToCheck
    end
    nodeToCheck.nodes = {}
    nodeToCheck.mudNodes = {}
    if node ~= nil then
        if getHasShaderParameter(node, "scratches_dirt_snow_wetness") then
            nodeToCheck.nodes[node] = useWetness
        else
            nodeToCheck.mudNodes[node] = useWetness
        end
    end
    nodeToCheck.updateFunc = updateFunc
    nodeToCheck.dirtAmount = 0
    nodeToCheck.dirtAmountSent = 0
    nodeToCheck.wetness = 0
    nodeToCheck.wetnessSent = 0
    nodeToCheck.colorChanged = false
    local defaultColor, _ = g_currentMission.environment:getDirtColors()
    nodeToCheck.color = { defaultColor[1], defaultColor[2], defaultColor[3] }
    nodeToCheck.defaultColor = { defaultColor[1], defaultColor[2], defaultColor[3] }
    if extraParams ~= nil then
        for i, v in pairs(extraParams) do
            nodeToCheck[i] = v
        end
    end
    table.insert(spec.washableNodes, nodeToCheck)
end
function Washable:removeAllSubWashableNodes(rootNode)
    if rootNode ~= nil then
        I3DUtil.iterateShaderParametersNodesRecursively(rootNode, Washable.SHADER_PARAMETERS, self.removeWashableNode, self)
    end
end
function Washable:removeWashableNode(node)
    if node ~= nil then
        local i = 1
        for i = i, #self.spec_washable.washableNodes do
            spec.washableNodes[i].nodes[node] = nil
            spec.washableNodes[i].mudNodes[node] = nil
        end
    end
end
function Washable:getDirtMultiplier()
    local multiplier = self:getLastSpeed() < 1 and 0 or 1
    if self.isOnField then
        multiplier = multiplier * self.spec_washable.fieldMultiplier
        local wetness = g_currentMission.environment.weather:getGroundWetness()
        if wetness > 0 then
        end
    end
    return multiplier
end
function Washable:getWorkDirtMultiplier()
    return self.spec_washable.workMultiplier
end
function Washable:getWashDuration()
    return self.spec_washable.washDuration
end
function Washable.getIntervalMultiplier()
    return g_currentMission.missionInfo.dirtInterval == 1 and 0 or (g_currentMission.missionInfo.dirtInterval == 2 and 0.25 or (g_currentMission.missionInfo.dirtInterval == 3 and 0.5 or (g_currentMission.missionInfo.dirtInterval == 4 and 1 or 1)))
end
function Washable:getAllowsWashingByType(type)
    return self.spec_washable.blockedWashTypes[type] ~= nil
end
function Washable:updateDebugValues(values)
    local spec = self.spec_washable
    if spec.washableNodes ~= nil then
        local allowsWashingByRain = self:getAllowsWashingByType(Washable.WASHTYPE_RAIN)
        local rainScale = 0
        local timeSinceLastRain = 0
        local temperature = 0
        if allowsWashingByRain then
            local weather = g_currentMission.environment.weather
            rainScale = weather:getRainFallScale()
            timeSinceLastRain = weather:getTimeSinceLastRain()
            temperature = weather:getCurrentTemperature()
        end
        local weather = false
        if rainScale > 0.1 then
            weather = false
            if timeSinceLastRain < 30 then
                weather = temperature > 0
            end
        end
        local changeWetness = 0
        if weather then
            changeWetness = 3600000 * spec.wetDuration * (1 + math.min(self.lastSpeed * 3600 / 10, 1))
        end
        table.insert(values, {
            ["name"] = "Dirt Multiplier",
            ["value"] = string.format("%.3f", self:getDirtMultiplier())
        })
        for i, nodeData in ipairs(spec.washableNodes) do
            local changedAmountDirt, changedAmountWetness = nodeData.updateFunc(self, nodeData, 3600000, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
            local changedAmountWetness
            if weather then
            else
                changedAmountWetness = changedAmountWetness - 3600000 * spec.dryDuration * ((1 - nodeData.dirtAmount) * 0.5 + 0.5) * (1 + math.min(self.lastSpeed * 3600 / 10, 1))
            end
            table.insert(values, {
                ["name"] = "WashableNode" .. i,
                ["value"] = string.format("%.4f a/h (%.2f) (color %.2f %.2f %.2f) (wetness: %.2f , %.4f a/min)", changedAmountDirt, spec.washableNodes[i].dirtAmount, nodeData.color[1], nodeData.color[2], nodeData.color[3], nodeData.wetness, changedAmountWetness / 60)
            })
        end
    end
end