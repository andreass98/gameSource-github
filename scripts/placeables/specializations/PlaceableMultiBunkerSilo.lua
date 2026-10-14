PlaceableMultiBunkerSilo = {}
function PlaceableMultiBunkerSilo.prerequisitesPresent(specializations)
    return true
end
function PlaceableMultiBunkerSilo.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("bunkerSilo", g_i18n:getText("configuration_bunkerSilo"), "bunkerSilo", PlaceableConfigurationItem)
end
function PlaceableMultiBunkerSilo.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableMultiBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableMultiBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableMultiBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableMultiBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableMultiBunkerSilo)
    SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableMultiBunkerSilo)
end
function PlaceableMultiBunkerSilo.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateBunkerSiloWalls", PlaceableMultiBunkerSilo.updateBunkerSiloWalls)
    SpecializationUtil.registerFunction(placeableType, "setWallVisibility", PlaceableMultiBunkerSilo.setWallVisibility)
    SpecializationUtil.registerFunction(placeableType, "getIsBunkerSiloExtendable", PlaceableMultiBunkerSilo.getIsBunkerSiloExtendable)
end
function PlaceableMultiBunkerSilo.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementPosition", PlaceableMultiBunkerSilo.getPlacementPosition)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementRotation", PlaceableMultiBunkerSilo.getPlacementRotation)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getHasOverlap", PlaceableMultiBunkerSilo.getHasOverlap)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "startPlacementCheck", PlaceableMultiBunkerSilo.startPlacementCheck)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableMultiBunkerSilo.canBeSold)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableMultiBunkerSilo.setOwnerFarmId)
end
function PlaceableMultiBunkerSilo.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("MultiBunkerSilo")
    schema:register(XMLValueType.BOOL, basePath .. ".bunkerSilo#isExtendable", "Checks if silo is extendable. If set \'siloToSiloDistance\' needs to be provided as well", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".bunkerSilo#siloToSiloDistance", "Silo to silo distance required for aligning multiple silos of the same type next to each other")
    schema:register(XMLValueType.FLOAT, basePath .. ".bunkerSilo#snapDistance", "Snap distance for building an array of the same silo", "siloToSiloDistance * 1.1")
    schema:register(XMLValueType.STRING, basePath .. ".bunkerSilo#sellWarningText", "Sell warning text")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallLeft#node", "Left wall node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallLeft#collision", "Left wall collision")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallBack#node", "Back wall node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallBack#collision", "Back wall collision")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallRight#node", "Right wall node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallRight#collision", "Right wall collision")
    BunkerSilo.registerXMLPaths(schema, (basePath .. ".bunkerSilo.bunkerSiloConfigurations.bunkerSiloConfiguration(?)") .. ".bunkerSilo(?)")
    schema:setXMLSpecializationType()
end
function PlaceableMultiBunkerSilo.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("MultiBunkerSilo")
    BunkerSilo.registerSavegameXMLPaths(schema, basePath .. ".bunkerSilo(?)")
    schema:setXMLSpecializationType()
end
function PlaceableMultiBunkerSilo:onLoad(_)
    local spec = self.spec_multiBunkerSilo
    spec.bunkerSilos = {}
    local bunkerSiloConfigurationId = Utils.getNoNil(self.configurations.bunkerSilo, 1)
    local configKey = string.format("%s.bunkerSiloConfigurations.bunkerSiloConfiguration(%d)", "placeable.bunkerSilo", bunkerSiloConfigurationId - 1)
    local leftWallNode = self.xmlFile:getValue("placeable.bunkerSilo.wallLeft#node", nil, self.components, self.i3dMappings)
    if leftWallNode ~= nil then
        spec.wallLeft = {}
        spec.wallLeft.node = leftWallNode
        spec.wallLeft.visible = true
        spec.wallLeft.collision = self.xmlFile:getValue("placeable.bunkerSilo.wallLeft#collision", nil, self.components, self.i3dMappings)
    end
    local backWallNode = self.xmlFile:getValue("placeable.bunkerSilo.wallRight#node", nil, self.components, self.i3dMappings)
    if backWallNode ~= nil then
        spec.wallRight = {}
        spec.wallRight.node = backWallNode
        spec.wallRight.visible = true
        spec.wallRight.collision = self.xmlFile:getValue("placeable.bunkerSilo.wallRight#collision", nil, self.components, self.i3dMappings)
    end
    local rightWallNode = self.xmlFile:getValue("placeable.bunkerSilo.wallBack#node", nil, self.components, self.i3dMappings)
    if rightWallNode ~= nil then
        spec.wallRight = {}
        spec.wallRight.node = rightWallNode
        spec.wallRight.visible = true
        spec.wallRight.collision = self.xmlFile:getValue("placeable.bunkerSilo.wallBack#collision", nil, self.components, self.i3dMappings)
    end
    spec.sellWarningText = g_i18n:convertText(self.xmlFile:getValue("placeable.bunkerSilo#sellWarningText", "$l10n_info_bunkerSiloNotEmpty"))
    for _, key in self.xmlFile:iterator(configKey .. ".bunkerSilo") do
        local bunkerSilo = BunkerSilo.new(self.isServer, self.isClient)
        if not bunkerSilo:load(self.components, self.xmlFile, key, self.i3dMappings) then
            bunkerSilo:delete()
            return
        end
        table.insert(spec.bunkerSilos, bunkerSilo)
    end
    spec.isExtendable = self.xmlFile:getValue("placeable.bunkerSilo#isExtendable", false)
    if spec.isExtendable then
        spec.siloSiloDistance = self.xmlFile:getValue("placeable.bunkerSilo#siloToSiloDistance")
        if spec.siloSiloDistance == nil then
            Logging.xmlError(self.xmlFile, "Bunker Silo is marked as extendable but \'placeable.bunkerSilo#siloToSiloDistance\' is not set")
            self:setLoadingState(PlaceableLoadingState.ERROR)
            return
        end
        spec.snapDistance = self.xmlFile:getValue("placeable.bunkerSilo#snapDistance") or spec.siloSiloDistance * 1.1
    end
end
function PlaceableMultiBunkerSilo:onDelete()
    local spec = self.spec_multiBunkerSilo
    self:updateBunkerSiloWalls(true)
    for i, bunkerSilo in ipairs_reverse(spec.bunkerSilos) do
        bunkerSilo:delete()
        table.remove(spec.bunkerSilos, i)
    end
    g_currentMission.placeableSystem:removeBunkerSilo(self)
end
function PlaceableMultiBunkerSilo:onFinalizePlacement()
    local ownerFarmId = self:getOwnerFarmId()
    self:updateBunkerSiloWalls(false)
    for _, bunkerSilo in ipairs(self.spec_multiBunkerSilo.bunkerSilos) do
        bunkerSilo:register(true)
        bunkerSilo:setOwnerFarmId(ownerFarmId, true)
    end
    g_currentMission.placeableSystem:addBunkerSilo(self)
end
function PlaceableMultiBunkerSilo:onReadStream(streamId, connection)
    for _, bunkerSilo in ipairs(self.spec_multiBunkerSilo.bunkerSilos) do
        local bunkerSiloId = NetworkUtil.readNodeObjectId(streamId)
        bunkerSilo:readStream(streamId, connection)
        g_client:finishRegisterObject(bunkerSilo, bunkerSiloId)
    end
end
function PlaceableMultiBunkerSilo:onWriteStream(streamId, connection)
    for _, bunkerSilo in ipairs(self.spec_multiBunkerSilo.bunkerSilos) do
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(bunkerSilo))
        bunkerSilo:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, bunkerSilo)
    end
end
function PlaceableMultiBunkerSilo:loadFromXMLFile(xmlFile, key)
    local isSuccessful = true
    for i, bunkerSilo in ipairs(self.spec_multiBunkerSilo.bunkerSilos) do
        if not bunkerSilo:loadFromXMLFile(xmlFile, (string.format("%s.bunkerSilo(%d)", key, i - 1))) then
            isSuccessful = false
        end
    end
    return isSuccessful
end
function PlaceableMultiBunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
    for i, bunkerSilo in ipairs(self.spec_multiBunkerSilo.bunkerSilos) do
        bunkerSilo:saveToXMLFile(xmlFile, string.format("%s.bunkerSilo(%d)", key, i - 1), usedModNames)
    end
end
function PlaceableMultiBunkerSilo:setWallVisibility(isLeftVisible, isBackVisible, _)
    local spec = self.spec_multiBunkerSilo
    if spec.wallLeft ~= nil then
        isLeftVisible = isLeftVisible or spec.wallLeft.visible
        if spec.wallLeft.visible ~= isLeftVisible then
            spec.wallLeft.visible = isLeftVisible
            setVisibility(spec.wallLeft.node, isLeftVisible)
            if spec.wallLeft.collision ~= nil then
                setRigidBodyType(spec.wallLeft.collision, isLeftVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
            end
        end
    end
    if spec.wallBack ~= nil then
        isBackVisible = isBackVisible or spec.wallBack.visible
        if spec.wallBack.visible ~= isBackVisible then
            spec.wallBack.visible = isBackVisible
            setVisibility(spec.wallBack.node, isBackVisible)
            if spec.wallBack.collision ~= nil then
                setRigidBodyType(spec.wallBack.collision, isBackVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
            end
        end
    end
    if spec.wallRight ~= nil then
        local isRightVisible = isLeftVisible or spec.wallRight.visible
        if spec.wallRight.visible ~= isRightVisible then
            spec.wallRight.visible = isRightVisible
            setVisibility(spec.wallRight.node, isRightVisible)
            if spec.wallRight.collision ~= nil then
                setRigidBodyType(spec.wallRight.collision, isRightVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
            end
        end
    end
end
function PlaceableMultiBunkerSilo:getIsBunkerSiloExtendable()
    return self.spec_multiBunkerSilo.isExtendable
end
function PlaceableMultiBunkerSilo:updateBunkerSiloWalls(isDeleting)
    if self.rootNode ~= nil then
        local x, y, z = getWorldTranslation(self.rootNode)
        for _, placeable in ipairs(g_currentMission.placeableSystem:getBunkerSilos()) do
            if placeable:getIsBunkerSiloExtendable() and (placeable ~= self and (placeable:getOwnerFarmId() == self:getOwnerFarmId() and placeable.configFileName == self.configFileName)) then
                local lx, _, lz = worldToLocal(placeable.rootNode, x, y, z)
                if MathUtil.vector2Length(lx, lz) < self.spec_multiBunkerSilo.siloSiloDistance + 0.5 then
                    if isDeleting then
                        if lx > 0 then
                            placeable:setWallVisibility(true, nil, nil)
                        elseif lz < 0 then
                            placeable:setWallVisibility(nil, true, nil)
                        else
                            placeable:setWallVisibility(nil, nil, true)
                        end
                    elseif isLeft then
                        placeable:setWallVisibility(false, nil, nil)
                    elseif isBack then
                        placeable:setWallVisibility(nil, false, nil)
                    else
                        placeable:setWallVisibility(nil, nil, false)
                    end
                end
            end
        end
    end
end
function PlaceableMultiBunkerSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
    local spec = self.spec_multiBunkerSilo
    superFunc(self, farmId, noEventSend)
    if spec.bunkerSilos ~= nil then
        for _, bunkerSilo in ipairs(spec.bunkerSilos) do
            bunkerSilo:setOwnerFarmId(farmId, true)
        end
    end
end
function PlaceableMultiBunkerSilo:onSell()
    for _, bunkerSilo in ipairs(self.spec_multiBunkerSilo.bunkerSilos) do
        bunkerSilo:clearSiloArea()
    end
end
function PlaceableMultiBunkerSilo:canBeSold(_)
    local spec = self.spec_multiBunkerSilo
    for _, bunkerSilo in ipairs(spec.bunkerSilos) do
        if bunkerSilo.fillLevel > 0 then
            return true, spec.sellWarningText
        end
    end
    return true, nil
end
function PlaceableMultiBunkerSilo:startPlacementCheck(superFunc, x, y, z, rotY)
    superFunc(self, x, y, z, rotY)
    if x == nil then
        return
    elseif self.spec_multiBunkerSilo.isExtendable then
        spec.foundSnappingSilo = nil
        spec.foundSnappingSiloSide = 0
        local nearestDistance = spec.snapDistance
        for _, placeable in ipairs(g_currentMission.placeableSystem:getBunkerSilos()) do
            if placeable:getOwnerFarmId() == g_localPlayer.farmId and placeable.configFileName == self.configFileName then
                local lx, _, lz = worldToLocal(placeable.rootNode, x, y, z)
                local distance = MathUtil.vector2Length(lx, lz)
                if distance < nearestDistance then
                    spec.foundSnappingSilo = placeable
                    spec.foundSnappingSiloSide = math.sign(lx)
                    nearestDistance = distance
                end
            end
        end
    end
end
function PlaceableMultiBunkerSilo:getHasOverlap(superFunc, x, y, z, rotY, checkFunc)
    local spec = self.spec_multiBunkerSilo
    return superFunc(self, x, y, z, rotY, spec.foundSnappingSilo ~= nil and function(hitObjectId)
        -- upvalues: (copy) spec, (copy) checkFunc
        if g_currentMission:getNodeObject(hitObjectId) == spec.foundSnappingSilo then
            return false
        end
        if checkFunc ~= nil then
            return checkFunc(hitObjectId)
        end
        return hitObjectId ~= g_terrainNode
    end or checkFunc)
end
function PlaceableMultiBunkerSilo:getPlacementRotation(superFunc, x, y, z)
    local spec, dx, _ = superFunc(self, x, y, z)
    local spec = self.spec_multiBunkerSilo
    if spec.foundSnappingSilo ~= nil then
        local dx, _, dz = localDirectionToWorld(spec.foundSnappingSilo.rootNode, 0, 0, 1)
        dx = MathUtil.getYRotationFromDirection(dx, dz)
        _ = 0
    end
    return spec, dx, _
end
function PlaceableMultiBunkerSilo:getPlacementPosition(superFunc, x, y, z)
    local spec
    spec, y, z = superFunc(self, x, y, z)
    local spec = self.spec_multiBunkerSilo
    if spec.foundSnappingSilo ~= nil then
        spec, y, z = localToWorld(spec.foundSnappingSilo.rootNode, spec.siloSiloDistance * spec.foundSnappingSiloSide, 0, 0)
    end
    return spec, y, z
end