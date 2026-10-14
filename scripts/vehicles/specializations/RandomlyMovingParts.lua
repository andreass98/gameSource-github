RandomlyMovingParts = {}
RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE = 50
RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY = "vehicle.randomlyMovingParts.randomlyMovingPart(?)"
RandomlyMovingParts.PRESETS = {}
RandomlyMovingParts.PRESETS.SOWINGMACHINE = {}
RandomlyMovingParts.PRESETS.SOWINGMACHINE.noiseFrequency = { 5, 23, 65 }
RandomlyMovingParts.PRESETS.SOWINGMACHINE.noiseAmount = { 0.4, 0.4, 0.2 }
RandomlyMovingParts.PRESETS.SOWINGMACHINE.hasBumps = false
RandomlyMovingParts.PRESETS.CULTIVATOR = {}
RandomlyMovingParts.PRESETS.CULTIVATOR.noiseFrequency = { 5, 23, 65 }
RandomlyMovingParts.PRESETS.CULTIVATOR.noiseAmount = { 0, 0.05, 0.05 }
RandomlyMovingParts.PRESETS.CULTIVATOR.hasBumps = true
RandomlyMovingParts.PRESETS.CULTIVATOR.bumpFrequency = 20
RandomlyMovingParts.PRESETS.CULTIVATOR.bumpDuration = 0.25
function RandomlyMovingParts.prerequisitesPresent(specializations)
    return true
end
function RandomlyMovingParts.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("RandomlyMovingParts")
    schema:register(XMLValueType.FLOAT, "vehicle.randomlyMovingParts#maxUpdateDistance", RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE)
    schema:register(XMLValueType.NODE_INDEX, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#node", "Node")
    schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#refNodeIndex", "Ground reference node index")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#speedScale", "Speed scale", 1)
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#speedVariance", "Random variance in the speed scale", 0.1)
    schema:register(XMLValueType.TIME, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#fadeTime", "Fade in and fade out time", 1)
    local names = {}
    for name, _ in pairs(RandomlyMovingParts.PRESETS) do
        table.insert(names, name)
    end
    schema:register(XMLValueType.STRING, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#preset", "Name of the preset to use for random value behaviour (%s)", "SOWINGMACHINE", nil, names)
    schema:register(XMLValueType.VECTOR_3, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#noiseFrequency", "The frequency of the different offsets that is applied", "used from preset")
    schema:register(XMLValueType.VECTOR_3, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#noiseAmount", "The max. offset for each frequency", "used from preset")
    schema:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#hasBumps", "The max. offset for each frequency", "used from preset")
    schema:register(XMLValueType.TIME, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#bumpFrequency", "Max. time between bumps", "used from preset")
    schema:register(XMLValueType.TIME, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#bumpDuration", "Duration of the bump", "used from preset")
    schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotAxis", "Rotation axis")
    schema:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotMax", "Max. delta rotation value in position direction")
    schema:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotMin", "Max. delta rotation value in negative direction", "Inverted rotMax value")
    schema:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotStart", "Initial rotation value on the defined axis", "Current value from i3d")
    schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transAxis", "Translation axis")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transMax", "Max. delta translation value in position direction")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transMin", "Max. delta translation value in negative direction", "Inverted rotMax value")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#transStart", "Initial translation value on the defined axis", "Current value from i3d")
    schema:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#isSpeedDependent", "Speed will adjust based on vehicle moving speed", true)
    schema:register(XMLValueType.NODE_INDEX, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#node", "Node that receives the same value")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#scale", "Scale that is applied to the random value (use -1 to invert the value)", 1)
    schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotAxis", "Rotation axis")
    schema:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotMax", "Max. delta rotation value in position direction")
    schema:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotMin", "Max. delta rotation value in negative direction", "Inverted rotMax value")
    schema:register(XMLValueType.ANGLE, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotStart", "Initial rotation value on the defined axis", "Current value from i3d")
    schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transAxis", "Translation axis")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transMax", "Max. delta translation value in position direction")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transMin", "Max. delta translation value in negative direction", "Inverted rotMax value")
    schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#transStart", "Initial translation value on the defined axis", "Current value from i3d")
    schema:setXMLSpecializationType()
end
function RandomlyMovingParts.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadRandomlyMovingPartFromXML", RandomlyMovingParts.loadRandomlyMovingPartFromXML)
    SpecializationUtil.registerFunction(vehicleType, "updateRandomlyMovingPart", RandomlyMovingParts.updateRandomlyMovingPart)
    SpecializationUtil.registerFunction(vehicleType, "getIsRandomlyMovingPartActive", RandomlyMovingParts.getIsRandomlyMovingPartActive)
end
function RandomlyMovingParts.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", RandomlyMovingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RandomlyMovingParts)
end
function RandomlyMovingParts:onLoad(_)
    local spec = self.spec_randomlyMovingParts
    spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.randomlyMovingParts#maxUpdateDistance", RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE)
    spec.nodes = {}
    for _, key in self.xmlFile:iterator("vehicle.randomlyMovingParts.randomlyMovingPart") do
        local randomlyMovingPart = {}
        if self:loadRandomlyMovingPartFromXML(randomlyMovingPart, self.xmlFile, key) then
            table.insert(spec.nodes, randomlyMovingPart)
        end
    end
    if not self.isClient or #spec.nodes == 0 then
        SpecializationUtil.removeEventListener(self, "onUpdate", RandomlyMovingParts)
    end
end
function RandomlyMovingParts:onUpdate(dt, _, _, _)
    local spec = self.spec_randomlyMovingParts
    if self.currentUpdateDistance < spec.maxUpdateDistance and self:getLastSpeed() > 0.1 then
        for _, part in pairs(spec.nodes) do
            self:updateRandomlyMovingPart(part, dt)
        end
    end
end
function RandomlyMovingParts:loadRandomlyMovingPartFromXML(part, xmlFile, key)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotMean")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotVariance")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotTimeMean")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotTimeVariance")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#pauseMean")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#pauseVariance")
    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(xmlFile, "Unknown node for randomlyMovingPart in \'%s\'", key)
        return false
    end
    part.node = node
    if self.getGroundReferenceNodeFromIndex ~= nil then
        local refNodeIndex = xmlFile:getValue(key .. "#refNodeIndex")
        if refNodeIndex ~= nil then
            if refNodeIndex == 0 then
                Logging.xmlWarning(xmlFile, "Unknown ground reference node in \'%s\'! Indices start with \'0\'", key .. "#refNodeIndex")
            else
                part.groundReferenceNode = self:getGroundReferenceNodeFromIndex(refNodeIndex) or part.groundReferenceNode
            end
        end
    end
    part.isSpeedDependent = xmlFile:getValue(key .. "#isSpeedDependent", true)
    part.speedScale = xmlFile:getValue(key .. "#speedScale", 1)
    part.speedVariance = xmlFile:getValue(key .. "#speedVariance", 0.1)
    part.speedScale = part.speedScale + (math.random() * part.speedVariance - part.speedVariance * 0.5)
    part.fadeTime = 1 / xmlFile:getValue(key .. "#fadeTime", 1)
    local refNodeIndex = xmlFile:getValue(key .. "#preset", "SOWINGMACHINE")
    local groundReferenceNode = RandomlyMovingParts.PRESETS[string.upper(refNodeIndex)] or RandomlyMovingParts.PRESETS.SOWINGMACHINE
    part.noiseFrequency = xmlFile:getValue(key .. "#noiseFrequency", groundReferenceNode.noiseFrequency, true)
    part.noiseAmount = xmlFile:getValue(key .. "#noiseAmount", groundReferenceNode.noiseAmount, true)
    part.hasBumps = xmlFile:getValue(key .. "#hasBumps", groundReferenceNode.hasBumps)
    if part.hasBumps then
        part.bumpFrequency = xmlFile:getValue(key .. "#bumpFrequency", groundReferenceNode.bumpFrequency or 10)
        part.bumpNextTime = part.bumpFrequency * math.random()
        part.bumpTimer = 0
        part.bumpDuration = xmlFile:getValue(key .. "#bumpDuration", groundReferenceNode.bumpDuration or 0.25)
    end
    part.rotAxis = xmlFile:getValue(key .. "#rotAxis", nil)
    if part.rotAxis ~= nil then
        part.rotMax = xmlFile:getValue(key .. "#rotMax", 0)
        part.rotMin = xmlFile:getValue(key .. "#rotMin") or -part.rotMax
        part.rotation = { getRotation(part.node) }
        part.initialRotation = { getRotation(part.node) }
        part.rotStart = xmlFile:getValue(key .. "#rotStart")
        if part.rotStart ~= nil then
            part.rotation[part.rotAxis] = part.rotStart
            part.initialRotation[part.rotAxis] = part.rotStart
            setRotation(part.node, part.initialRotation[1], part.initialRotation[2], part.initialRotation[3])
        end
    end
    part.transAxis = xmlFile:getValue(key .. "#transAxis", nil)
    if part.transAxis ~= nil then
        part.transMax = xmlFile:getValue(key .. "#transMax", 0)
        part.transMin = xmlFile:getValue(key .. "#transMin") or -part.transMax
        part.translation = { getTranslation(part.node) }
        part.initialTranslation = { getTranslation(part.node) }
        part.transStart = xmlFile:getValue(key .. "#transStart")
        if part.transStart ~= nil then
            part.translation[part.transAxis] = part.transStart
            part.initialTranslation[part.transAxis] = part.transStart
            setTranslation(part.node, part.initialTranslation[1], part.initialTranslation[2], part.initialTranslation[3])
        end
    end
    if part.rotAxis == nil and part.transAxis == nil then
        Logging.xmlWarning(xmlFile, "No rotation or translation axis for randomlyMovingPart in \'%s\'", key)
        return false
    end
    part.nodes = {}
    for _, nodeKey in xmlFile:iterator(key .. ".node") do
        local node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local nodeData = {
                ["node"] = node,
                ["deltaScale"] = xmlFile:getValue(nodeKey .. "#scale", 1),
                ["rotAxis"] = xmlFile:getValue(key .. "#rotAxis", part.rotAxis)
            }
            if nodeData.rotAxis ~= nil then
                nodeData.rotMax = xmlFile:getValue(key .. "#rotMax", part.rotMax or 0)
                nodeData.rotMin = xmlFile:getValue(key .. "#rotMin") or -nodeData.rotMax
                nodeData.rotation = { getRotation(nodeData.node) }
                nodeData.initialRotation = { getRotation(nodeData.node) }
                nodeData.rotStart = xmlFile:getValue(key .. "#rotStart")
                if nodeData.rotStart ~= nil then
                    nodeData.rotation[nodeData.rotAxis] = nodeData.rotStart
                    nodeData.initialRotation[nodeData.rotAxis] = nodeData.rotStart
                    setRotation(nodeData.node, nodeData.initialRotation[1], nodeData.initialRotation[2], nodeData.initialRotation[3])
                end
            end
            nodeData.transAxis = xmlFile:getValue(key .. "#transAxis", part.transAxis)
            if nodeData.transAxis ~= nil then
                nodeData.transMax = xmlFile:getValue(key .. "#transMax", part.transMax or 0)
                nodeData.transMin = xmlFile:getValue(key .. "#transMin") or -nodeData.transMax
                nodeData.translation = { getTranslation(nodeData.node) }
                nodeData.initialTranslation = { getTranslation(nodeData.node) }
                nodeData.transStart = xmlFile:getValue(key .. "#transStart")
                if nodeData.transStart ~= nil then
                    nodeData.translation[nodeData.transAxis] = nodeData.transStart
                    nodeData.initialTranslation[nodeData.transAxis] = nodeData.transStart
                    setTranslation(nodeData.node, nodeData.initialTranslation[1], nodeData.initialTranslation[2], nodeData.initialTranslation[3])
                end
            end
            if part.rotAxis ~= nil or part.transAxis ~= nil then
                table.insert(part.nodes, nodeData)
            end
        end
    end
    part.isActive = true
    part.time = math.random()
    part.alpha = 0
    return true
end
local function updateNodeData(vehicle, nodeData, delta, alpha)
    if nodeData.deltaScale ~= nil then
    end
    if nodeData.rotAxis ~= nil then
        local deltaRotation = nodeData.rotMin * math.abs((math.min(delta, 0)))
        local deltaRotation = deltaRotation + nodeData.rotMax * math.abs((math.max(delta, 0)))
        nodeData.rotation[nodeData.rotAxis] = nodeData.initialRotation[nodeData.rotAxis] + deltaRotation * alpha
        setRotation(nodeData.node, nodeData.rotation[1], nodeData.rotation[2], nodeData.rotation[3])
        if vehicle.setMovingToolDirty ~= nil then
            vehicle:setMovingToolDirty(nodeData.node)
        end
    end
    if nodeData.transAxis ~= nil then
        nodeData.translation[nodeData.transAxis] = nodeData.initialTranslation[nodeData.transAxis] + (nodeData.transMin + delta * (nodeData.transMax - nodeData.transMin)) * alpha
        setTranslation(nodeData.node, nodeData.translation[1], nodeData.translation[2], nodeData.translation[3])
        if vehicle.setMovingToolDirty ~= nil then
            vehicle:setMovingToolDirty(nodeData.node)
        end
    end
end
function RandomlyMovingParts:updateRandomlyMovingPart(part, dt)
    -- upvalues: (copy) updateNodeData
    local speed
    if part.isSpeedDependent then
        speed = self.lastMovedDistance * self.movingDirection * 0.2
    else
        speed = dt * 0.00033
    end
    part.isActive = self:getIsRandomlyMovingPartActive(part)
    if part.isActive then
        if part.alpha < 1 then
            part.alpha = math.min(part.alpha + dt * part.fadeTime, 1)
        end
        if part.hasBumps then
            if not part.isSpeedDependent or self:getLastSpeed() > 1 then
                part.bumpNextTime = part.bumpNextTime - dt
                if part.bumpNextTime <= 0 then
                    part.bumpTimer = part.bumpDuration
                    part.bumpNextTime = part.bumpFrequency * math.random()
                end
            end
            if part.bumpTimer > 0 then
                part.bumpTimer = part.bumpTimer - dt
            end
        end
    elseif part.alpha > 0 then
        part.alpha = math.max(part.alpha - dt * part.fadeTime, 0)
    end
    if part.alpha > 0 then
        part.time = part.time + speed * part.speedScale
        local nodeData = part.time * part.noiseFrequency[2]
        local bumpAlpha = math.sin(part.time * part.noiseFrequency[1]) * part.noiseAmount[1] + math.sin(nodeData) * part.noiseAmount[2]
        local delta = bumpAlpha + math.sin(part.time * part.noiseFrequency[3]) * part.noiseAmount[3]
        if part.hasBumps and part.bumpTimer > 0 then
            delta = math.min(delta + math.sin((1 - part.bumpTimer / part.bumpDuration) * 3.141592653589793), 1)
        end
        updateNodeData(self, part, delta, part.alpha)
        for i, nodeData in ipairs(part.nodes) do
            updateNodeData(self, nodeData, delta, part.alpha)
        end
    end
end
function RandomlyMovingParts:getIsRandomlyMovingPartActive(part)
    local retValue = true
    if part.groundReferenceNode ~= nil then
        retValue = self:getIsGroundReferenceNodeActive(part.groundReferenceNode)
    end
    return retValue
end