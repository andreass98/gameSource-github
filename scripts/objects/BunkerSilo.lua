BunkerSilo = {}
local BunkerSilo_mt = Class(BunkerSilo, Object)
InitStaticObjectClass(BunkerSilo, "BunkerSilo")
BunkerSilo.STATE_FILL = 0
BunkerSilo.STATE_CLOSED = 1
BunkerSilo.STATE_FERMENTED = 2
BunkerSilo.STATE_DRAIN = 3
BunkerSilo.NUM_STATES = 4
BunkerSilo.COMPACTING_BASE_MASS = 5
BunkerSilo.MILLISECONDS_PER_DAY = 86400000
function BunkerSilo:onCreate(id)
    Logging.error("BunkerSilo.onCreate is deprecated!")
end
function BunkerSilo.new(isServer, isClient, customMt)
    -- upvalues: (copy) BunkerSilo_mt
    local self = Object.new(isServer, isClient, customMt or BunkerSilo_mt)
    self.interactionTriggerNode = nil
    self.bunkerSiloArea = {}
    self.bunkerSiloArea.offsetFront = 0
    self.bunkerSiloArea.offsetBack = 0
    self.acceptedFillTypes = {}
    self.inputFillType = FillType.CHAFF
    self.outputFillType = FillType.SILAGE
    self.fermentingFillType = FillType.TARP
    self.isOpenedAtFront = false
    self.isOpenedAtBack = false
    self.distanceToCompactedFillLevel = 100
    self.fermentingPercent = 0
    self.fillLevel = 0
    self.compactedFillLevel = 0
    self.compactedPercent = 0
    self.emptyThreshold = 100
    self.playerInRange = false
    self.vehiclesInRange = {}
    self.numVehiclesInRange = 0
    self.siloIsFullWarningTimer = 0
    self.siloIsFullWarningDuration = 2000
    self.updateTimer = 0
    self.activatable = BunkerSiloActivatable.new(self)
    self.state = BunkerSilo.STATE_FILL
    self.bunkerSiloDirtyFlag = self:getNextDirtyFlag()
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    return self
end
function BunkerSilo:load(components, xmlFile, key, i3dMappings)
    self.bunkerSiloArea.start = xmlFile:getValue(key .. ".area#startNode", nil, components, i3dMappings)
    self.bunkerSiloArea.width = xmlFile:getValue(key .. ".area#widthNode", nil, components, i3dMappings)
    self.bunkerSiloArea.height = xmlFile:getValue(key .. ".area#heightNode", nil, components, i3dMappings)
    local data = self.bunkerSiloArea
    local inputFillTypeName = self.bunkerSiloArea
    local inputFillTypeIndex = self.bunkerSiloArea
    local i, fillTypeIndex, leftWallNode = getWorldTranslation(self.bunkerSiloArea.start)
    data.sx = i
    inputFillTypeName.sy = fillTypeIndex
    inputFillTypeIndex.sz = leftWallNode
    local data = self.bunkerSiloArea
    local inputFillTypeName = self.bunkerSiloArea
    local inputFillTypeIndex = self.bunkerSiloArea
    local i, fillTypeIndex, leftWallNode = getWorldTranslation(self.bunkerSiloArea.width)
    data.wx = i
    inputFillTypeName.wy = fillTypeIndex
    inputFillTypeIndex.wz = leftWallNode
    local data = self.bunkerSiloArea
    local inputFillTypeName = self.bunkerSiloArea
    local inputFillTypeIndex = self.bunkerSiloArea
    local i, fillTypeIndex, leftWallNode = getWorldTranslation(self.bunkerSiloArea.height)
    data.hx = i
    inputFillTypeName.hy = fillTypeIndex
    inputFillTypeIndex.hz = leftWallNode
    self.bunkerSiloArea.dhx = self.bunkerSiloArea.hx - self.bunkerSiloArea.sx
    self.bunkerSiloArea.dhy = self.bunkerSiloArea.hy - self.bunkerSiloArea.sy
    self.bunkerSiloArea.dhz = self.bunkerSiloArea.hz - self.bunkerSiloArea.sz
    local data = self.bunkerSiloArea
    local inputFillTypeName = self.bunkerSiloArea
    local inputFillTypeIndex = self.bunkerSiloArea
    local i, fillTypeIndex, leftWallNode = MathUtil.vector3Normalize(self.bunkerSiloArea.dhx, self.bunkerSiloArea.dhy, self.bunkerSiloArea.dhz)
    data.dhx_norm = i
    inputFillTypeName.dhy_norm = fillTypeIndex
    inputFillTypeIndex.dhz_norm = leftWallNode
    self.bunkerSiloArea.dwx = self.bunkerSiloArea.wx - self.bunkerSiloArea.sx
    self.bunkerSiloArea.dwy = self.bunkerSiloArea.wy - self.bunkerSiloArea.sy
    self.bunkerSiloArea.dwz = self.bunkerSiloArea.wz - self.bunkerSiloArea.sz
    local data = self.bunkerSiloArea
    local inputFillTypeName = self.bunkerSiloArea
    local inputFillTypeIndex = self.bunkerSiloArea
    local i, fillTypeIndex, leftWallNode = MathUtil.vector3Normalize(self.bunkerSiloArea.dwx, self.bunkerSiloArea.dwy, self.bunkerSiloArea.dwz)
    data.dwx_norm = i
    inputFillTypeName.dwy_norm = fillTypeIndex
    inputFillTypeIndex.dwz_norm = leftWallNode
    self.bunkerSiloArea.inner = {}
    self.bunkerSiloArea.inner.start = xmlFile:getValue(key .. ".innerArea#startNode", self.bunkerSiloArea.start, components, i3dMappings)
    self.bunkerSiloArea.inner.width = xmlFile:getValue(key .. ".innerArea#widthNode", self.bunkerSiloArea.width, components, i3dMappings)
    self.bunkerSiloArea.inner.height = xmlFile:getValue(key .. ".innerArea#heightNode", self.bunkerSiloArea.height, components, i3dMappings)
    local data = self.bunkerSiloArea.inner
    local inputFillTypeName = self.bunkerSiloArea.inner
    local inputFillTypeIndex = self.bunkerSiloArea.inner
    local i, fillTypeIndex, leftWallNode = getWorldTranslation(self.bunkerSiloArea.inner.start)
    data.sx = i
    inputFillTypeName.sy = fillTypeIndex
    inputFillTypeIndex.sz = leftWallNode
    local data = self.bunkerSiloArea.inner
    local inputFillTypeName = self.bunkerSiloArea.inner
    local inputFillTypeIndex = self.bunkerSiloArea.inner
    local i, fillTypeIndex, leftWallNode = getWorldTranslation(self.bunkerSiloArea.inner.width)
    data.wx = i
    inputFillTypeName.wy = fillTypeIndex
    inputFillTypeIndex.wz = leftWallNode
    local data = self.bunkerSiloArea.inner
    local inputFillTypeName = self.bunkerSiloArea.inner
    local inputFillTypeIndex = self.bunkerSiloArea.inner
    local i, fillTypeIndex, leftWallNode = getWorldTranslation(self.bunkerSiloArea.inner.height)
    data.hx = i
    inputFillTypeName.hy = fillTypeIndex
    inputFillTypeIndex.hz = leftWallNode
    self.interactionTriggerNode = xmlFile:getValue(key .. ".interactionTrigger#node", nil, components, i3dMappings)
    if self.interactionTriggerNode ~= nil then
        addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
    end
    self.acceptedFillTypes = {}
    local data = xmlFile:getValue(key .. "#acceptedFillTypes", "chaff grass_windrow dryGrass_windrow"):split(" ")
    local i = 1
    local inputFillTypeName = #data
    local inputFillTypeIndex = 1
    for i = i, inputFillTypeName, inputFillTypeIndex do
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(data[i])
        if fillTypeIndex == nil then
            Logging.warning("\'%s\' is an invalid fillType for bunkerSilo \'%s\'!", tostring(data[i]), key .. "#acceptedFillTypes")
        else
            self.acceptedFillTypes[fillTypeIndex] = true
        end
    end
    local inputFillTypeName = xmlFile:getValue(key .. "#inputFillType", "chaff")
    local inputFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(inputFillTypeName)
    if inputFillTypeIndex == nil then
        Logging.warning("\'%s\' is an invalid input fillType for bunkerSilo \'%s\'!", tostring(inputFillTypeName), key .. "#inputFillType")
    else
        self.inputFillType = inputFillTypeIndex
    end
    local i = xmlFile:getValue(key .. "#outputFillType", "silage")
    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(i)
    if fillTypeIndex == nil then
        Logging.warning("\'%s\' is an invalid output fillType for bunkerSilo \'%s\'!", tostring(i), key .. "#outputFillType")
    else
        self.outputFillType = fillTypeIndex
    end
    g_densityMapHeightManager:setConvertingFillTypeAreas(self.bunkerSiloArea, self.acceptedFillTypes, self.inputFillType)
    self.distanceToCompactedFillLevel = xmlFile:getValue(key .. "#distanceToCompactedFillLevel", self.distanceToCompactedFillLevel)
    self.openingLength = xmlFile:getValue(key .. "#openingLength", 5)
    local leftWallNode = xmlFile:getValue(key .. ".wallLeft#node", nil, components, i3dMappings)
    if leftWallNode ~= nil then
        self.wallLeft = {}
        self.wallLeft.node = leftWallNode
        self.wallLeft.visible = true
        self.wallLeft.collision = xmlFile:getValue(key .. ".wallLeft#collision", nil, components, i3dMappings)
    end
    local rightWallNode = xmlFile:getValue(key .. ".wallRight#node", nil, components, i3dMappings)
    if rightWallNode ~= nil then
        self.wallRight = {}
        self.wallRight.node = rightWallNode
        self.wallRight.visible = true
        self.wallRight.collision = xmlFile:getValue(key .. ".wallRight#collision", nil, components, i3dMappings)
    end
    self.fillLevel = 0
    self.distanceToCompactedFillLevel = self.distanceToCompactedFillLevel / g_currentMission.missionInfo.economicDifficulty
    self:setState(BunkerSilo.STATE_FILL)
    return true
end
function BunkerSilo:delete()
    if self.interactionTriggerNode ~= nil then
        removeTrigger(self.interactionTriggerNode)
    end
    g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
    g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
    g_messageCenter:unsubscribeAll(self)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    BunkerSilo:superClass().delete(self)
end
function BunkerSilo:readStream(streamId, connection)
    BunkerSilo:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        self:setState((streamReadUIntN(streamId, 3)))
        self.isOpenedAtFront = streamReadBool(streamId)
        self.isOpenedAtBack = streamReadBool(streamId)
        self.fillLevel = streamReadFloat32(streamId)
        self.compactedPercent = streamReadUIntN(streamId, 7)
        self.fermentingPercent = NetworkUtil.readCompressedPercentages(streamId)
    end
end
function BunkerSilo:writeStream(streamId, connection)
    BunkerSilo:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteUIntN(streamId, self.state, 3)
        streamWriteBool(streamId, self.isOpenedAtFront)
        streamWriteBool(streamId, self.isOpenedAtBack)
        streamWriteFloat32(streamId, self.fillLevel)
        streamWriteUIntN(streamId, self.compactedPercent, 7)
        NetworkUtil.writeCompressedPercentages(streamId, self.fermentingPercent)
    end
end
function BunkerSilo:readUpdateStream(streamId, timestamp, connection)
    BunkerSilo:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local state = streamReadUIntN(streamId, 3)
        if state ~= self.state then
            self:setState(state, true)
        end
        self.fillLevel = streamReadFloat32(streamId)
        self.isOpenedAtFront = streamReadBool(streamId)
        self.isOpenedAtBack = streamReadBool(streamId)
        if self.state == BunkerSilo.STATE_FILL then
            self.compactedPercent = streamReadUIntN(streamId, 7)
            return
        end
        if self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
            self.fermentingPercent = NetworkUtil.readCompressedPercentages(streamId)
        end
    end
end
function BunkerSilo:writeUpdateStream(streamId, connection, dirtyMask)
    BunkerSilo:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.bunkerSiloDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, self.state, 3)
            streamWriteFloat32(streamId, self.fillLevel)
            streamWriteBool(streamId, self.isOpenedAtFront)
            streamWriteBool(streamId, self.isOpenedAtBack)
            if self.state == BunkerSilo.STATE_FILL then
                streamWriteUIntN(streamId, self.compactedPercent, 7)
                return
            end
            if self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
                NetworkUtil.writeCompressedPercentages(streamId, self.fermentingPercent)
            end
        end
    end
end
function BunkerSilo:loadFromXMLFile(xmlFile, key)
    local state = xmlFile:getValue(key .. "#state")
    if state ~= nil and (state >= 0 and state < BunkerSilo.NUM_STATES) then
        self:setState(state)
    end
    self.fillLevel = xmlFile:getValue(key .. "#fillLevel") or self.fillLevel
    local compactedFillLevel = xmlFile:getValue(key .. "#compactedFillLevel")
    if compactedFillLevel ~= nil then
        self.compactedFillLevel = math.clamp(compactedFillLevel, 0, self.fillLevel)
    end
    local fermentingTime = MathUtil.getFlooredPercent
    local offWx = self.compactedFillLevel
    local offWz = self.fillLevel
    self.compactedPercent = fermentingTime(math.min(offWx, offWz), self.fillLevel)
    local fermentingTime = xmlFile:getValue(key .. "#fermentingTime")
    if fermentingTime ~= nil then
        self.fermentingPercent = fermentingTime / (BunkerSilo.MILLISECONDS_PER_DAY * g_currentMission.environment.daysPerPeriod)
    end
    self.isOpenedAtFront = xmlFile:getValue(key .. "#openedAtFront", false)
    self.isOpenedAtBack = xmlFile:getValue(key .. "#openedAtBack", false)
    if self.isOpenedAtFront then
        self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.outputFillType)
    else
        self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.fermentingFillType)
    end
    if self.isOpenedAtBack then
        self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.outputFillType)
    else
        self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.fermentingFillType)
    end
    if self.fillLevel > 0 and self.state == BunkerSilo.STATE_DRAIN then
        local area = self.bunkerSiloArea
        local offWx = area.wx - area.sx
        local offWz = area.wz - area.sz
        local offHx = offWx * offWx + offWz * offWz
        local offW = math.sqrt(offHx)
        local offHx = area.hx - area.sx
        local offHz = area.hz - area.sz
        local offWScale = offHx * offHx + offHz * offHz
        local offH = math.sqrt(offWScale)
        if offW > 0.001 and offH > 0.001 then
            local offWScale = math.min(0.45, 0.9 / offW)
            local offWx = offWx * offWScale
            local offWz = offWz * offWScale
            local offHScale = math.min(0.45, 0.9 / offH)
            local offHx = offHx * offHScale
            local offHz = offHz * offHScale
            if DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx + offWx + offHx, area.sz + offWz + offHz, area.wx - offWx + offHx, area.wz - offWz + offHz, area.hx + offWx - offHx, area.hz + offWz - offHz) + DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, area.sx + offWx + offHx, area.sz + offWz + offHz, area.wx - offWx + offHx, area.wz - offWz + offHz, area.hx + offWx - offHx, area.hz + offWz - offHz) < self.emptyThreshold * 0.5 then
                DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.fermentingFillType)
                DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.outputFillType)
                self:setState(BunkerSilo.STATE_FILL, false)
            end
        end
        DensityMapHeightUtil.changeFillTypeAtArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.inputFillType, self.outputFillType)
    elseif self.fillLevel > 0 and (self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED) then
        local area = self.bunkerSiloArea
        DensityMapHeightUtil.changeFillTypeAtArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.inputFillType, self.fermentingFillType)
    elseif self.state == BunkerSilo.STATE_FILL then
        local area = self.bunkerSiloArea
        local offWx, offWz, offW = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
        if self.emptyThreshold < offWx and 0.5 * offW < offWz then
            local offHx, offHz, offH = DensityMapHeightUtil.getFillLevelAtArea(self.inputFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
            if offHz < 0.1 * offH then
                self:setState(BunkerSilo.STATE_FERMENTED, false)
            end
        end
    end
    return true
end
function BunkerSilo:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#state", self.state)
    xmlFile:setValue(key .. "#fillLevel", self.fillLevel)
    xmlFile:setValue(key .. "#compactedFillLevel", self.compactedFillLevel)
    xmlFile:setValue(key .. "#fermentingTime", self.fermentingPercent * BunkerSilo.MILLISECONDS_PER_DAY * g_currentMission.environment.daysPerPeriod)
    xmlFile:setValue(key .. "#openedAtFront", self.isOpenedAtFront)
    xmlFile:setValue(key .. "#openedAtBack", self.isOpenedAtBack)
end
function BunkerSilo:update(_)
    if self:getCanInteract(true) then
        local fillTypeIndex = self.inputFillType
        if self.state == BunkerSilo.STATE_CLOSED or (self.state == BunkerSilo.STATE_FERMENTED or self.state == BunkerSilo.STATE_DRAIN) then
            fillTypeIndex = self.outputFillType
        end
        local fillTypeName = ""
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillType ~= nil then
            fillTypeName = fillType.title
        end
        g_currentMission:addExtraPrintText(string.format("%s %s: %d", g_i18n:getText("info_fillLevel"), fillTypeName, self.fillLevel))
        if self.state == BunkerSilo.STATE_FILL then
            g_currentMission:addExtraPrintText(string.format("%s %d%%", g_i18n:getText("info_compacting"), self.compactedPercent))
        elseif self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
            local compactingFactor = g_i18n:getText("info_fermenting")
            g_currentMission:addExtraPrintText(string.format("%s %d%%", compactingFactor, (math.ceil(self.fermentingPercent * 100))))
        end
    end
    if self.isServer and self.state == BunkerSilo.STATE_FILL then
        for vehicle, state in pairs(self.vehiclesInRange) do
            if state and vehicle:getIsActive() then
                local distance = vehicle.lastMovedDistance
                if distance > 0 then
                    local compactingFactor = vehicle:getTotalMass(false) / BunkerSilo.COMPACTING_BASE_MASS
                    local compactingScale = 1
                    if vehicle.getBunkerSiloCompacterScale ~= nil then
                        compactingScale = vehicle:getBunkerSiloCompacterScale() or compactingScale
                    end
                    local deltaCompact = distance * (compactingFactor * compactingScale) * self.distanceToCompactedFillLevel
                    if vehicle.getWheels ~= nil then
                        local wheels = vehicle:getWheels()
                        local numWheels = #wheels
                        if numWheels > 0 then
                            local wheelsOnSilo = 0
                            local wheelsInAir = 0
                            for _, wheel in ipairs(wheels) do
                                if wheel.physics.contact == WheelContactType.GROUND_HEIGHT then
                                elseif wheel.physics.contact == WheelContactType.NONE then
                                end
                            end
                            if wheelsOnSilo > 0 then
                            else
                                deltaCompact = 0
                            end
                        else
                            deltaCompact = 0
                        end
                    end
                    if deltaCompact > 0 then
                        local wheels = math.min(self.compactedFillLevel + deltaCompact, self.fillLevel)
                        if wheels ~= self.compactedFillLevel then
                            self:updateCompacting(wheels)
                        end
                    end
                end
            end
        end
    end
    if g_currentMission ~= nil and (g_currentMission.bunkerScore ~= nil and g_currentMission.bunkerScore < self.fillLevel) then
        g_currentMission.bunkerScore = self.fillLevel
    end
    self:raiseActive()
end
function BunkerSilo:updateTick(dt)
    if self.isServer then
        self.updateTimer = self.updateTimer - dt
        if self.updateTimer <= 0 then
            self.updateTimer = 200 + math.random() * 100
            self:updateFillLevel()
            if self.fillLevel ~= self.fillLevel then
                self:updateCompacting(self.compactedFillLevel)
            end
        end
    end
    if not self.adjustedOpeningLength then
        self.adjustedOpeningLength = true
        self.openingLength = math.max(self.openingLength, DensityMapHeightUtil.getDefaultMaxRadius(self.outputFillType) + 1)
    end
end
function BunkerSilo:updateCompacting(compactedFillLevel)
    self.compactedFillLevel = compactedFillLevel
    self.compactedPercent = MathUtil.getFlooredPercent(math.min(self.compactedFillLevel, self.fillLevel), self.fillLevel)
    self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
end
function BunkerSilo:updateFillLevel()
    local fillLevel = self.fillLevel
    local fillType = self.inputFillType
    if fillType ~= FillType.UNKNOWN then
        if self.state == BunkerSilo.STATE_FILL then
            fillLevel = DensityMapHeightUtil.getFillLevelAtArea(fillType, self.bunkerSiloArea.inner.sx, self.bunkerSiloArea.inner.sz, self.bunkerSiloArea.inner.wx, self.bunkerSiloArea.inner.wz, self.bunkerSiloArea.inner.hx, self.bunkerSiloArea.inner.hz)
        elseif self.state == BunkerSilo.STATE_CLOSED then
            fillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
        elseif self.state == BunkerSilo.STATE_FERMENTED then
            fillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz) + DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
        elseif self.state == BunkerSilo.STATE_DRAIN then
            fillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz) + DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
            if fillLevel < self.emptyThreshold then
                DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.fermentingFillType)
                DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.outputFillType)
                self:setState(BunkerSilo.STATE_FILL, true)
            end
        end
    end
    self.fillLevel = fillLevel
end
function BunkerSilo:setState(state, showNotification)
    if state ~= self.state then
        if state == BunkerSilo.STATE_FILL then
            self.fermentingPercent = 0
            self.compactedFillLevel = 0
            self.compactedPercent = 0
            self.isOpenedAtFront = false
            self.isOpenedAtBack = false
            self.bunkerSiloArea.offsetFront = 0
            self.bunkerSiloArea.offsetBack = 0
            if showNotification then
                self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloIsEmpty"))
            end
            if self.isServer then
                g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
                g_densityMapHeightManager:setConvertingFillTypeAreas(self.bunkerSiloArea, self.acceptedFillTypes, self.inputFillType)
            end
        elseif state == BunkerSilo.STATE_CLOSED then
            local area = self.bunkerSiloArea
            local offsetFront = self:getBunkerAreaOffset(true, 0, self.inputFillType)
            local offsetBack = self:getBunkerAreaOffset(false, 0, self.inputFillType)
            local x0 = area.sx + offsetFront * area.dhx_norm
            local z0 = area.sz + offsetFront * area.dhz_norm
            local x1 = x0 + area.dwx
            local z1 = z0 + area.dwz
            local x2 = area.sx + area.dhx - offsetBack * area.dhx_norm
            local z2 = area.sz + area.dhz - offsetBack * area.dhz_norm
            if self.isServer then
                DensityMapHeightUtil.changeFillTypeAtArea(x0, z0, x1, z1, x2, z2, self.inputFillType, self.fermentingFillType)
                g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
                g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
            end
            g_currentMission.tireTrackSystem:eraseParallelogram(x0, z0, x1, z1, x2, z2)
            FSDensityMapUtil.resetDisplacementArea(x0, z0, x1, z1, x2, z2)
            if showNotification then
                self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloCovered"))
            end
        elseif state == BunkerSilo.STATE_FERMENTED then
            if showNotification then
                self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloDoneFermenting"))
            end
        elseif state == BunkerSilo.STATE_DRAIN then
            self.bunkerSiloArea.offsetFront = 0
            self.bunkerSiloArea.offsetBack = 0
            if showNotification then
                self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloOpened"))
            end
            if self.isServer then
                g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
                g_densityMapHeightManager:setFixedFillTypesArea(self.bunkerSiloArea, {
                    [self.outputFillType] = true
                })
            end
        end
        self.state = state
        if self.isServer then
            self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
        end
    end
end
function BunkerSilo:showBunkerMessage(msg)
    if g_localPlayer.farmId == self:getOwnerFarmId() then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msg)
    end
end
function BunkerSilo:openSilo(px, py, pz)
    self:setState(BunkerSilo.STATE_DRAIN, true)
    self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.fermentingFillType)
    self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.fermentingFillType)
    if self:getIsCloserToFront(px, py, pz) and not self.isOpenedAtFront then
        self:switchFillTypeAtOffset(true, self.bunkerSiloArea.offsetFront, self.openingLength)
        self.isOpenedAtFront = true
        self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
    elseif not self.isOpenedAtBack then
        self:switchFillTypeAtOffset(false, self.bunkerSiloArea.offsetBack, self.openingLength)
        self.isOpenedAtBack = true
        self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
    end
end
function BunkerSilo:getBunkerAreaOffset(updateAtFront, offset, fillType)
    local area = self.bunkerSiloArea
    local hl = MathUtil.vector3Length(area.dhx, area.dhy, area.dhz)
    while offset <= hl - 1 do
        local pos
        if updateAtFront then
            pos = offset
        else
            pos = hl - offset - 1
        end
        local d1x = pos * area.dhx_norm
        local d1z = pos * area.dhz_norm
        if DensityMapHeightUtil.getFillLevelAtArea(fillType, area.sx + d1x, area.sz + d1z, area.wx + d1x, area.wz + d1z, area.sx + (pos + 1) * hx, area.sz + (pos + 1) * hz) > 0 then
            return offset
        end
        offset = offset + 1
    end
    local d1x = hl - 1
    return math.max(d1x, 0)
end
function BunkerSilo:switchFillTypeAtOffset(switchAtFront, offset, length)
    local a0x, a0z, a1x, a1z, a2x, a2z
    if switchAtFront then
        a1x = self.bunkerSiloArea.sx + offset * self.bunkerSiloArea.dhx_norm + area.dwx
        a1z = area.sz + offset * area.dhz_norm + area.dwz
        a2x = area.sx + (offset + length) * area.dhx_norm
        a2z = area.sz + (offset + length) * area.dhz_norm
    else
        a1x = area.hx - offset * area.dhx_norm + area.dwx
        a1z = area.hz - offset * area.dhz_norm + area.dwz
        a2x = area.hx - (offset + length) * area.dhx_norm
        a2z = area.hz - (offset + length) * area.dhz_norm
    end
    DensityMapHeightUtil.changeFillTypeAtArea(a0x, a0z, a1x, a1z, a2x, a2z, self.fermentingFillType, self.outputFillType)
end
function BunkerSilo:getIsCloserToFront(ix, iy, iz)
    local area = self.bunkerSiloArea
    local distFront = MathUtil.vector3Length(area.sx + 0.5 * area.dwx + area.offsetFront * area.dhx_norm - ix, area.sy + 0.5 * area.dwy + area.offsetFront * area.dhy_norm - iy, area.sz + 0.5 * area.dwz + area.offsetFront * area.dhz_norm - iz)
    return distFront < MathUtil.vector3Length(area.sx + 0.5 * area.dwx + area.dhx - area.offsetBack * area.dhx_norm - ix, area.sy + 0.5 * area.dwy + area.dhy - area.offsetBack * area.dhy_norm - iy, area.sz + 0.5 * area.dwz + area.dhz - area.offsetBack * area.dhz_norm - iz)
end
function BunkerSilo:getCanInteract(showInformationOnly)
    local localPlayer = g_localPlayer
    if localPlayer == nil then
        return false
    end
    if showInformationOnly then
        if not localPlayer:getIsInVehicle() and self.playerInRange then
            return true
        end
        local playerVehicle = localPlayer:getCurrentVehicle()
        if playerVehicle ~= nil then
            for vehicle in pairs(self.vehiclesInRange) do
                if vehicle:getIsActiveForInput(true) and vehicle == playerVehicle then
                    return true
                end
            end
        end
    elseif not localPlayer:getIsInVehicle() and self.playerInRange then
        return true
    end
    return false
end
function BunkerSilo:getCanCloseSilo()
    return self.state == BunkerSilo.STATE_FILL and self.fillLevel > 0 and self.compactedPercent >= 100
end
function BunkerSilo:getCanOpenSilo()
    if self.state ~= BunkerSilo.STATE_FERMENTED and self.state ~= BunkerSilo.STATE_DRAIN then
        return false
    end
    local ix, iy, iz = self:getInteractionPosition()
    if ix ~= nil then
        local closerToFront = self:getIsCloserToFront(ix, iy, iz)
        if closerToFront and not self.isOpenedAtFront then
            return true
        end
        if not (closerToFront or self.isOpenedAtBack) then
            return true
        end
    end
    return false
end
function BunkerSilo:clearSiloArea()
    local xs, _, zs = getWorldTranslation(self.bunkerSiloArea.start)
    local xw, _, zw = getWorldTranslation(self.bunkerSiloArea.width)
    local xh, _, zh = getWorldTranslation(self.bunkerSiloArea.height)
    DensityMapHeightUtil.clearArea(xs, zs, xw, zw, xh, zh)
end
function BunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
    if self.wallLeft ~= nil then
        isLeftVisible = Utils.getNoNil(isLeftVisible, self.wallLeft.visible)
        if self.wallLeft.visible ~= isLeftVisible then
            self.wallLeft.visible = isLeftVisible
            setVisibility(self.wallLeft.node, isLeftVisible)
            if self.wallLeft.collision ~= nil then
                setRigidBodyType(self.wallLeft.collision, isLeftVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
            end
        end
    end
    if self.wallRight ~= nil then
        isRightVisible = Utils.getNoNil(isRightVisible, self.wallRight.visible)
        if self.wallRight.visible ~= isRightVisible then
            self.wallRight.visible = isRightVisible
            setVisibility(self.wallRight.node, isRightVisible)
            if self.wallRight.collision ~= nil then
                setRigidBodyType(self.wallRight.collision, isRightVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
            end
        end
    end
end
function BunkerSilo:onHourChanged()
    if self.state == BunkerSilo.STATE_CLOSED and self.isServer then
        self.fermentingPercent = math.min(self.fermentingPercent + 0.041666666666666664 / g_currentMission.environment.daysPerPeriod, 1)
        self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
        if self.fermentingPercent >= 0.999 then
            self:setState(BunkerSilo.STATE_FERMENTED, true)
        end
    end
end
function BunkerSilo:getInteractionPosition()
    local localPlayer = g_localPlayer
    if localPlayer == nil then
        return nil
    elseif localPlayer:getIsInVehicle() or not self.playerInRange then
        local playerVehicle = localPlayer:getCurrentVehicle()
        if self.vehiclesInRange[playerVehicle] == nil then
            return nil
        else
            return getWorldTranslation(self.vehiclesInRange[playerVehicle].components[1].node)
        end
    else
        return localPlayer:getPosition()
    end
end
function BunkerSilo:interactionTriggerCallback(_, otherId, onEnter, onLeave, _, otherShapeId)
    if onEnter or onLeave then
        if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
            local vehicle = g_currentMission:getNodeObject(otherShapeId)
            if vehicle ~= nil and vehicle:isa(Vehicle) then
                if onEnter then
                    if self.vehiclesInRange[vehicle] == nil then
                        self.vehiclesInRange[vehicle] = true
                        self.numVehiclesInRange = self.numVehiclesInRange + 1
                        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                        if vehicle.setBunkerSiloInteractorCallback ~= nil then
                            vehicle:setBunkerSiloInteractorCallback(BunkerSilo.onChangedFillLevelCallback, self)
                            return
                        end
                    end
                elseif self.vehiclesInRange[vehicle] then
                    self.vehiclesInRange[vehicle] = nil
                    self.numVehiclesInRange = self.numVehiclesInRange - 1
                    if self.numVehiclesInRange == 0 and not self.playerInRange then
                        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
                    end
                    if vehicle.setBunkerSiloInteractorCallback ~= nil then
                        vehicle:setBunkerSiloInteractorCallback(nil)
                    end
                end
            end
        else
            if onEnter then
                self.playerInRange = true
                g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                return
            end
            self.playerInRange = false
            if self.numVehiclesInRange == 0 then
                g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
                return
            end
        end
    end
end
function BunkerSilo:onChangedFillLevelCallback(vehicle, fillDelta, _, x, y, z)
    if fillDelta < 0 then
        if x == nil or (y == nil or z == nil) then
            x, y, z = getWorldTranslation(vehicle.components[1].node)
        end
        local closerToFront = self:getIsCloserToFront(x, y, z)
        if closerToFront then
            if self.isOpenedAtFront then
                local p1 = MathUtil.getProjectOnLineParameter(x, z, self.bunkerSiloArea.sx, self.bunkerSiloArea.sz, self.bunkerSiloArea.dhx_norm, self.bunkerSiloArea.dhz_norm)
                if area.offsetFront - self.openingLength < p1 then
                    local offset = self:getBunkerAreaOffset(true, area.offsetFront, self.fermentingFillType)
                    local targetOffset = math.max(p1, offset) + length
                    self:switchFillTypeAtOffset(true, area.offsetFront, targetOffset - area.offsetFront)
                    area.offsetFront = targetOffset
                    return
                end
            end
        elseif self.isOpenedAtBack then
            local p1 = MathUtil.getProjectOnLineParameter(x, z, area.hx, area.hz, -area.dhx_norm, -area.dhz_norm)
            if area.offsetBack - length < p1 then
                local offset = self:getBunkerAreaOffset(false, area.offsetBack, self.fermentingFillType)
                local targetOffset = math.max(p1, offset) + length
                self:switchFillTypeAtOffset(false, area.offsetBack, targetOffset - area.offsetBack)
                area.offsetBack = targetOffset
            end
        end
    end
end
function BunkerSilo.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Area start node (placed in the middle of the walls)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Area width node (placed in the middle of the walls)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Area height node (placed in the middle of the walls)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".innerArea#startNode", "Inner area start node (Used to detect fill level - placed 25cm from inner walls)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".innerArea#widthNode", "Inner area width node (Used to detect fill level - placed 25cm from inner walls)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".innerArea#heightNode", "Inner area height node (Used to detect fill level - placed 25cm from inner walls)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallLeft#node", "Left wall node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallLeft#collision", "Left wall collision")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallRight#node", "Right wall node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallRight#collision", "Right wall collision")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".interactionTrigger#node", "Interaction trigger node")
    schema:register(XMLValueType.STRING, basePath .. "#acceptedFillTypes", "Accepted fill types", "chaff grass_windrow dryGrass_windrow")
    schema:register(XMLValueType.STRING, basePath .. "#inputFillType", "Input fill type", "chaff")
    schema:register(XMLValueType.STRING, basePath .. "#outputFillType", "Output fill type", "silage")
    schema:register(XMLValueType.FLOAT, basePath .. "#distanceToCompactedFillLevel", "Distance to drive on bunker silo for full compaction", 100)
    schema:register(XMLValueType.FLOAT, basePath .. "#openingLength", "Opening length", 5)
end
function BunkerSilo.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#state", "Current silo state (FILL = 0, CLOSED = 1, FERMENTED = 2, DRAIN = 3)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Current fill level")
    schema:register(XMLValueType.FLOAT, basePath .. "#compactedFillLevel", "Compacted fill level")
    schema:register(XMLValueType.FLOAT, basePath .. "#fermentingTime", "Fermenting time")
    schema:register(XMLValueType.BOOL, basePath .. "#openedAtFront", "Is opened at front", false)
    schema:register(XMLValueType.BOOL, basePath .. "#openedAtBack", "Is opened at back", false)
end
BunkerSiloActivatable = {}
local BunkerSiloActivatable_mt = Class(BunkerSiloActivatable)
function BunkerSiloActivatable.new(bunkerSilo)
    -- upvalues: (copy) BunkerSiloActivatable_mt
    local self = setmetatable({}, BunkerSiloActivatable_mt)
    self.bunkerSilo = bunkerSilo
    self.activateText = "unknown"
    return self
end
function BunkerSiloActivatable:getIsActivatable()
    if not (self.bunkerSilo:getCanInteract() and (self.bunkerSilo:getCanCloseSilo() or self.bunkerSilo:getCanOpenSilo())) then
        return false
    end
    self:updateActivateText()
    return true
end
function BunkerSiloActivatable:getHasAccess(farmId)
    return g_currentMission.accessHandler:canFarmAccessOtherId(farmId, self.bunkerSilo:getOwnerFarmId())
end
function BunkerSiloActivatable:run()
    if self.bunkerSilo:getCanCloseSilo() then
        local text = string.namedFormat(g_i18n:getText("ui_doYouWantToCoverTheSilo"), "fillLevel", g_i18n:formatVolume(self.bunkerSilo.fillLevel, 0))
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) self
            if yes then
                if g_server ~= nil then
                    self.bunkerSilo:setState(BunkerSilo.STATE_CLOSED, true)
                    return
                end
                g_client:getServerConnection():sendEvent(BunkerSiloCloseEvent.new(self.bunkerSilo))
            end
        end, nil, text)
    elseif self.bunkerSilo:getCanOpenSilo() then
        local text, iy, iz = self.bunkerSilo:getInteractionPosition()
        if text ~= nil then
            if g_server == nil then
                g_client:getServerConnection():sendEvent(BunkerSiloOpenEvent.new(self.bunkerSilo, text, iy, iz))
            else
                self.bunkerSilo:openSilo(text, iy, iz)
            end
        end
    end
    self:updateActivateText()
end
function BunkerSiloActivatable:updateActivateText()
    self.activateText = "unknown"
    if self.bunkerSilo.state == BunkerSilo.STATE_FILL then
        self.activateText = g_i18n:getText("action_blanketSilo")
        return
    elseif self.bunkerSilo.state == BunkerSilo.STATE_FERMENTED then
        self.activateText = g_i18n:getText("action_openSilo")
    elseif self.bunkerSilo.state == BunkerSilo.STATE_DRAIN and not (self.bunkerSilo.isOpenedAtFront and self.bunkerSilo.isOpenedAtBack) then
        self.activateText = g_i18n:getText("action_openSilo")
    end
end