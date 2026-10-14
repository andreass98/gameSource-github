BeaconLight = {}
BeaconLight.LIGHT_TYPE_BITMASK = 8
local BeaconLight_mt = Class(BeaconLight)
function BeaconLight.new(vehicle, customMt)
    -- upvalues: (copy) BeaconLight_mt
    local self = setmetatable({}, customMt or BeaconLight_mt)
    self.vehicle = vehicle
    self.components = {}
    self.i3dMappings = {}
    self.staticLights = {}
    self.speed = 1
    self.realLightRangeScale = 1
    self.intensity = 1
    self.lastCameraDistance = 0
    self.requiresDirtyUpdate = false
    self.hasDynamicStaticLights = false
    self.isActive = false
    self.realLightActive = false
    return self
end
function BeaconLight:delete()
    if self.node ~= nil then
        delete(self.node)
        self.node = nil
    end
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
    g_currentMission:removeUpdateable(self)
end
function BeaconLight:setCallback(callback, callbackTarget)
    self.callback = callback
    self.callbackTarget = callbackTarget
end
function BeaconLight.loadFromVehicleXML(targetTable, xmlFile, key, vehicle)
    local xmlFilename = xmlFile:getValue(key .. "#filename", nil, vehicle.baseDirectory)
    if xmlFilename == nil then
        local linkNode = false
        local isReference = {}
        for realLight, useRealLights in xmlFile:iterator(key .. ".staticLight") do
            local realLightRangeScale = {
                ["node"] = xmlFile:getValue(useRealLights .. "#node", nil, vehicle.components, vehicle.i3dMappings)
            }
            if realLightRangeScale.node ~= nil then
                realLightRangeScale.intensity = xmlFile:getValue(useRealLights .. "#intensity", 1)
                realLightRangeScale.multiBlink = xmlFile:getValue(useRealLights .. "#multiBlink", false)
                realLightRangeScale.multiBlinkParameters = xmlFile:getValue(useRealLights .. "#multiBlinkParameters", "2 5 50 0", true)
                realLightRangeScale.uvOffsetParameter = xmlFile:getValue(useRealLights .. "#uvOffsetParameter", 0)
                realLightRangeScale.minDistance = xmlFile:getValue(useRealLights .. "#minDistance", 0)
                realLightRangeScale.intensityScaleMinDistance = xmlFile:getValue(useRealLights .. ".intensityScale#minDistance")
                realLightRangeScale.intensityScaleMinIntensity = xmlFile:getValue(useRealLights .. ".intensityScale#minIntensity")
                realLightRangeScale.intensityScaleMaxDistance = xmlFile:getValue(useRealLights .. ".intensityScale#maxDistance")
                realLightRangeScale.intensityScaleMaxIntensity = xmlFile:getValue(useRealLights .. ".intensityScale#maxIntensity")
                local intensity = false
                if realLightRangeScale.intensityScaleMinDistance ~= nil then
                    intensity = false
                    if realLightRangeScale.intensityScaleMinIntensity ~= nil then
                        intensity = false
                        if realLightRangeScale.intensityScaleMaxDistance ~= nil then
                            intensity = realLightRangeScale.intensityScaleMaxIntensity ~= nil
                        end
                    end
                end
                realLightRangeScale.hasDynamicIntensity = intensity
                linkNode = linkNode or realLightRangeScale.hasDynamicIntensity
                if not linkNode then
                    linkNode = realLightRangeScale.minDistance > 0
                end
                table.insert(isReference, realLightRangeScale)
            end
        end
        if isReference ~= nil and #isReference > 0 then
            local runtimeLoaded = xmlFile:getValue(key .. "#intensity", 1)
            local speed = xmlFile:getValue(key .. "#realLight", nil, vehicle.components, vehicle.i3dMappings)
            local realLight = xmlFile:getValue(key .. "#realLightRange", 1)
            local useRealLights = BeaconLight.new(vehicle)
            useRealLights:setXMLSettings(xmlFile:getValue(key .. "#speed"), runtimeLoaded, nil, nil)
            useRealLights:setRealLight(true, speed, realLight)
            useRealLights.staticLights = isReference
            useRealLights.hasStaticLights = true
            useRealLights.hasDynamicStaticLights = linkNode
            useRealLights:onFinished(true)
            table.insert(targetTable, useRealLights)
            return useRealLights
        end
    else
        local linkNode = xmlFile:getValue(key .. "#node", nil, vehicle.components, vehicle.i3dMappings)
        if linkNode ~= nil then
            local isReference, _, runtimeLoaded = getReferenceInfo(linkNode)
            if not (isReference and runtimeLoaded) then
                local speed = xmlFile:getValue(key .. "#speed")
                local realLight = xmlFile:getValue(key .. "#realLight", nil, vehicle.components, vehicle.i3dMappings)
                local useRealLights = xmlFile:getValue(key .. "#useRealLights", realLight ~= nil)
                local realLightRangeScale = xmlFile:getValue(key .. "#realLightRange", 1)
                local variationName = xmlFile:getValue(key .. "#variationName")
                local beaconLight = BeaconLight.new(vehicle)
                beaconLight:setXMLSettings(speed, xmlFile:getValue(key .. "#intensity", 1), xmlFile:getValue(key .. "#mountType"), variationName)
                beaconLight:setRealLight(useRealLights, realLight, realLightRangeScale)
                beaconLight:setCallback(function(success)
                    -- upvalues: (copy) targetTable, (copy) beaconLight
                    if success then
                        table.insert(targetTable, beaconLight)
                    end
                end)
                beaconLight:loadFromXML(linkNode, xmlFilename, vehicle.baseDirectory)
                return beaconLight
            end
            Logging.xmlWarning(xmlFile, "Beacon light link node \'%s\' is a runtime loaded reference, please load beacon lights only via XML!", getName(linkNode))
            return
        end
        Logging.xmlWarning(xmlFile, "Missing link node for beacon light in \'%s\'", key)
    end
    return nil
end
function BeaconLight:setXMLSettings(speed, intensity, mountType, variationName)
    self.speed = speed or self.speed
    self.intensity = intensity or self.intensity
    self.mountType = mountType
    self.variationName = variationName
end
function BeaconLight:setRealLight(useRealLights, customRealLight, realLightRangeScale)
    self.useRealLights = Utils.getNoNil(useRealLights, self.useRealLights)
    self.customRealLight = customRealLight
    self.realLightRangeScale = realLightRangeScale or self.realLightRangeScale
end
function BeaconLight:loadFromXML(linkNode, xmlFilename, baseDirectory)
    self.xmlFile = XMLFile.loadIfExists("BeaconLight", xmlFilename, BeaconLight.xmlSchema)
    if self.xmlFile == nil then
        if self.vehicle == nil then
            Logging.warning("Unable to load shared lights from xml \'%s\'", xmlFilename)
        else
            Logging.xmlWarning(self.vehicle.xmlFile, "Unable to load shared lights from xml \'%s\'", xmlFilename)
        end
        self:onFinished(false)
        return false
    end
    local filename = self.xmlFile:getValue("beaconLight.filename")
    if filename ~= nil then
        self.filename = Utils.getFilename(filename, baseDirectory)
        self.linkNode = linkNode
        if self.vehicle == nil then
            self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.onI3DLoaded, self, nil)
        else
            self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self, nil)
        end
        return true
    end
    Logging.xmlWarning(self.xmlFile, "Missing light i3d filename!")
    self.xmlFile:delete()
    self.xmlFile = nil
    self:onFinished(false)
    return false
end
function BeaconLight:onI3DLoaded(i3dNode, _, _)
    if self.vehicle == nil or not self.vehicle.isDeleted then
        if i3dNode ~= 0 then
            I3DUtil.loadI3DComponents(i3dNode, self.components)
            I3DUtil.loadI3DMapping(self.xmlFile, "beaconLight", self.components, self.i3dMappings)
            self.node = self.xmlFile:getValue("beaconLight.rootNode#node", "0", self.components, self.i3dMappings)
            if self.node ~= nil then
                self.nodesToRemove = {}
                self.variationRootNode = nil
                local variationKey = nil
                for _variationIndex, _variationKey in self.xmlFile:iterator("beaconLight.variations.variation") do
                    local name = self.xmlFile:getValue(_variationKey .. "#name")
                    if name ~= nil then
                        if self.variationName == nil and _variationIndex == 1 or self.variationName ~= nil and string.lower(name) == string.lower(self.variationName) then
                            self.variationRootNode = self.xmlFile:getValue(_variationKey .. "#rootNode", nil, self.components, self.i3dMappings)
                            variationKey = _variationKey
                        else
                            local node = self.xmlFile:getValue(_variationKey .. "#rootNode", nil, self.components, self.i3dMappings)
                            if node ~= nil then
                                self.nodesToRemove[node] = true
                            end
                        end
                    end
                end
                self:loadVariationFromXML(self.xmlFile, "beaconLight")
                if variationKey ~= nil then
                    self:loadVariationFromXML(self.xmlFile, variationKey)
                end
                local yOffset = 0
                for _variationKey, name in self.xmlFile:iterator("beaconLight.mountTypes.mountType") do
                    local node = self.xmlFile:getValue(name .. "#name")
                    if node ~= nil then
                        local node = self.xmlFile:getValue(name .. "#node", nil, self.components, self.i3dMappings)
                        if self.mountType == nil and _variationKey == 1 or self.mountType ~= nil and string.lower(node) == string.lower(self.mountType) then
                            yOffset = self.xmlFile:getValue(name .. "#yOffset", 0)
                            if node ~= nil then
                                setVisibility(node, true)
                            end
                        elseif node ~= nil then
                            self.nodesToRemove[node] = true
                        end
                    end
                end
                for _variationKey, name in pairs(self.nodesToRemove) do
                    if _variationKey ~= self.variationRootNode then
                        delete(_variationKey)
                    end
                end
                self.nodesToRemove = nil
                link(self.linkNode, self.node)
                setTranslation(self.node, 0, yOffset, 0)
            end
            delete(i3dNode)
        end
        self.xmlFile:delete()
        self.xmlFile = nil
        self:onFinished(self.node ~= nil and self.hasStaticLights)
    end
end
function BeaconLight:onFinished(success)
    for _, staticLight in ipairs(self.staticLights) do
        staticLight.useLightControlShaderParameter = getHasShaderParameter(staticLight.node, "lightControl")
        if staticLight.useLightControlShaderParameter then
            setShaderParameter(staticLight.node, "lightControl", 0, nil, nil, nil, false)
        else
            setShaderParameter(staticLight.node, "lightIds0", 0, 0, 0, 0, false)
            setShaderParameter(staticLight.node, "lightIds1", 0, 0, 0, 0, false)
            setShaderParameter(staticLight.node, "lightTypeBitMask", BeaconLight.LIGHT_TYPE_BITMASK, 0, 0, 0, false)
            setShaderParameter(staticLight.node, "lightUvOffsetBitMask", staticLight.uvOffsetParameter, 0, 0, 0, false)
        end
        setShaderParameter(staticLight.node, "blinkMulti", staticLight.multiBlinkParameters[1], staticLight.multiBlinkParameters[2], staticLight.multiBlinkParameters[3], staticLight.multiBlinkParameters[4], false)
        if staticLight.multiBlink or (staticLight.minDistance > 0 or staticLight.hasDynamicIntensity) then
            self.requiresDirtyUpdate = true
        end
    end
    if self.speed > 0 and self.rotatorNode ~= nil then
        setRotation(self.rotatorNode, 0, math.random(0, 6.283185307179586), 0)
        self.requiresDirtyUpdate = true
    end
    if (not self.useRealLights or self.customRealLight ~= nil) and self.realLightNode ~= nil then
        delete(self.realLightNode)
        self.realLightNode = nil
    end
    if self.customRealLight ~= nil then
        self.realLightNode = self.customRealLight
    end
    if self.realLightNode ~= nil then
        self.defaultColor = { getLightColor(self.realLightNode) }
        setVisibility(self.realLightNode, false)
        self.defaultLightRange = getLightRange(self.realLightNode)
        setLightRange(self.realLightNode, self.defaultLightRange * self.realLightRangeScale)
        setLightShadowPriority(self.realLightNode, 0.25)
    end
    if self.callback ~= nil then
        if self.callbackTarget ~= nil then
            self.callback(self.callbackTarget, success)
            return
        end
        self.callback(success)
    end
end
function BeaconLight:loadVariationFromXML(xmlFile, key)
    self.rotatorNode = xmlFile:getValue(key .. ".rotator#node", self.rotatorNode, self.components, self.i3dMappings)
    self.speed = xmlFile:getValue(key .. ".rotator#speed", self.speed or 0.015)
    self.realLightNode = xmlFile:getValue(key .. ".realLight#node", self.realLightNode, self.components, self.i3dMappings)
    if self.realLightNode ~= nil and not getHasClassId(self.realLightNode, ClassIds.LIGHT_SOURCE) then
        Logging.xmlWarning(xmlFile, "Node \'%s\' defined as light source for beacon light, but is not a light source!", getName(self.realLightNode))
        self.realLightNode = nil
    end
    if not xmlFile:getValue(key .. ".realLight#useRealLight", true) and self.realLightNode ~= nil then
        delete(self.realLightNode)
        self.realLightNode = nil
    end
    for _, staticLightKey in xmlFile:iterator(key .. ".staticLight") do
        local staticLight = {
            ["node"] = xmlFile:getValue(staticLightKey .. "#node", nil, self.components, self.i3dMappings)
        }
        if staticLight.node ~= nil then
            if staticLight.node == nil or getHasClassId(staticLight.node, ClassIds.SHAPE) then
                staticLight.intensity = xmlFile:getValue(staticLightKey .. "#intensity", 1)
                staticLight.multiBlink = xmlFile:getValue(staticLightKey .. "#multiBlink", false)
                staticLight.multiBlinkParameters = xmlFile:getValue(staticLightKey .. "#multiBlinkParameters", "2 5 50 0", true)
                staticLight.uvOffsetParameter = xmlFile:getValue(staticLightKey .. "#uvOffsetParameter", 0)
                staticLight.minDistance = xmlFile:getValue(staticLightKey .. "#minDistance", 0)
                staticLight.intensityScaleMinDistance = xmlFile:getValue(staticLightKey .. ".intensityScale#minDistance")
                staticLight.intensityScaleMinIntensity = xmlFile:getValue(staticLightKey .. ".intensityScale#minIntensity")
                staticLight.intensityScaleMaxDistance = xmlFile:getValue(staticLightKey .. ".intensityScale#maxDistance")
                staticLight.intensityScaleMaxIntensity = xmlFile:getValue(staticLightKey .. ".intensityScale#maxIntensity")
                staticLight.hasDynamicIntensity = staticLight.intensityScaleMinDistance ~= nil and staticLight.intensityScaleMinIntensity ~= nil and staticLight.intensityScaleMaxDistance ~= nil and staticLight.intensityScaleMaxIntensity ~= nil
                self.hasDynamicStaticLights = self.hasDynamicStaticLights or staticLight.hasDynamicIntensity or staticLight.minDistance > 0
                table.insert(self.staticLights, staticLight)
            else
                Logging.xmlWarning(xmlFile, "Node \'%s\' defined as shader node for beacon light, but is not a shape!", getName(staticLight.node))
            end
        end
    end
    local baseDirectory = #self.staticLights > 0
    self.hasStaticLights = baseDirectory
    self.device = BeaconLightManager.loadDeviceFromXML(xmlFile, key .. ".device") or self.device
    if xmlFile:hasProperty(key .. ".material") then
        local baseDirectory = ""
        local customEnvironment = ""
        if self.vehicle ~= nil then
            baseDirectory = self.vehicle.baseDirectory
            customEnvironment = self.vehicle.customEnvironment
        end
        local material = VehicleMaterial.new(baseDirectory)
        if material:loadFromXML(xmlFile, key .. ".material", customEnvironment) then
            material:apply(self.node)
        end
    end
end
function BeaconLight:update(dt)
    if self.rotatorNode ~= nil then
        rotate(self.rotatorNode, 0, self.speed * dt, 0)
    end
    if self.realLightActive and (self.hasStaticLights and self.staticLights[1].multiBlink) then
        local staticLight = self.staticLights[1]
        local blink = staticLight.multiBlinkParameters[1]
        local mTime = getShaderTimeSec() * staticLight.multiBlinkParameters[3] + staticLight.multiBlinkParameters[4]
        local b = math.sin(mTime)
        local r = b - math.max(mTime % ((blink * 2 + staticLight.multiBlinkParameters[2] * 2) * 3.141592653589793) - (blink * 2 - 1) * 3.141592653589793, 0) + 0.2
        local alpha = math.clamp(r, 0, 1)
        local r = self.defaultColor[1]
        local g = self.defaultColor[2]
        local b = self.defaultColor[3]
        setLightColor(self.realLightNode, r * alpha, g * alpha, b * alpha)
        local i = 0
        for i = i, getNumOfChildren(self.realLightNode) - 1 do
            setLightColor(getChildAt(self.realLightNode, i), r * alpha, g * alpha, b * alpha)
        end
    end
    if self.hasDynamicStaticLights then
        local staticLight = 0
        if self.node ~= nil then
            staticLight = calcDistanceFrom(self.node, g_cameraManager:getActiveCamera())
        end
        local pause = self.lastCameraDistance - staticLight
        if math.abs(pause) > 1 then
            for timeOffset, mTime in ipairs(self.staticLights) do
                if mTime.hasDynamicIntensity then
                    local r = math.max((staticLight - mTime.intensityScaleMinDistance) / (mTime.intensityScaleMaxDistance - mTime.intensityScaleMinDistance), 0)
                    local alpha = math.min(r, 1)
                    local r = (mTime.intensityScaleMinIntensity + (mTime.intensityScaleMaxIntensity - mTime.intensityScaleMinIntensity) * alpha) * self.intensity
                    if mTime.useLightControlShaderParameter then
                        setShaderParameter(mTime.node, "lightControl", r, nil, nil, nil, false)
                    else
                        setShaderParameter(mTime.node, "lightIds0", r, r, 0, 0, false)
                    end
                end
                if mTime.minDistance > 0 then
                    setVisibility(mTime.node, mTime.minDistance <= staticLight)
                end
            end
            self.lastCameraDistance = staticLight
        end
    end
end
function BeaconLight:setIsActive(isActive)
    if self.requiresDirtyUpdate then
        if isActive then
            g_currentMission:addUpdateable(self)
        else
            g_currentMission:removeUpdateable(self)
        end
    end
    if self.realLightNode ~= nil then
        if g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHTS) then
            self.realLightActive = isActive
        else
            self.realLightActive = false
        end
        setVisibility(self.realLightNode, self.realLightActive)
    end
    if self.node ~= nil and isActive then
        self.lastCameraDistance = calcDistanceFrom(self.node, g_cameraManager:getActiveCamera())
    end
    for _, staticLight in ipairs(self.staticLights) do
        local value = isActive and staticLight.intensity or 0
        if isActive and staticLight.hasDynamicIntensity then
            local alpha = math.min(math.max((self.lastCameraDistance - staticLight.intensityScaleMinDistance) / (staticLight.intensityScaleMaxDistance - staticLight.intensityScaleMinDistance), 0), 1)
            value = staticLight.intensityScaleMinIntensity + (staticLight.intensityScaleMaxIntensity - staticLight.intensityScaleMinIntensity) * alpha
        end
        local value = value * self.intensity
        if staticLight.useLightControlShaderParameter then
            setShaderParameter(staticLight.node, "lightControl", value, nil, nil, nil, false)
        else
            setShaderParameter(staticLight.node, "lightIds0", value, value, 0, 0, false)
        end
        if staticLight.minDistance > 0 then
            if isActive then
                setVisibility(staticLight.node, self.lastCameraDistance >= staticLight.minDistance)
            else
                setVisibility(staticLight.node, false)
            end
        end
    end
    self.isActive = isActive
end
function BeaconLight:setDeviceIsActive(isActive)
    local device = self.device
    if device ~= nil then
        if isActive then
            if device.deviceId == nil then
                device.deviceId = g_beaconLightManager:activateBeaconLight(device.mode, device.numLEDScale, device.rpm, device.brightnessScale)
                return
            end
        elseif device.deviceId ~= nil then
            g_beaconLightManager:deactivateBeaconLight(device.deviceId)
            device.deviceId = nil
        end
    end
end
function BeaconLight:onLightsRealBeaconLightChanged()
    if self.realLightNode ~= nil then
        if self.isActive and not g_gameSettings:getValue(GameSettings.SETTING.REAL_BEACON_LIGHTS) then
            self.realLightActive = false
        else
            self.realLightActive = self.isActive
        end
        setVisibility(self.realLightNode, self.realLightActive)
    end
end
function BeaconLight.spawnDebugBeacons(rootNode)
    local files = Files.getFilesRecursive("data/shared/assets/beaconLights")
    table.sort(files, function(a, b)
        return a.path < b.path
    end)
    if BeaconLight.debugBeaconLights ~= nil then
        for _, beaconLight in ipairs(BeaconLight.debugBeaconLights) do
            beaconLight:delete()
        end
    end
    BeaconLight.debugBeaconLights = {}
    local x = -1
    local _ = 0
    local beaconLight = 0
    local numLightsSuccess = 0
    local numLightsFailed = 0
    for _, file in ipairs(files) do
        if not file.isDirectory and file.filename:contains(".xml") then
            x = x - 2
            local z = 0
            local filename = string.gsub(file.path, getAppBasePath(), "")
            local tempXMLFile = XMLFile.loadIfExists("BeaconLight", filename, BeaconLight.xmlSchema)
            if tempXMLFile ~= nil then
                for _, mountTypeKey in tempXMLFile:iterator("beaconLight.mountTypes.mountType") do
                    local mountType = tempXMLFile:getValue(mountTypeKey .. "#name")
                    for _, variationKey in tempXMLFile:iterator("beaconLight.variations.variation") do
                        local variationName = tempXMLFile:getValue(variationKey .. "#name")
                        local _ = _ + 1
                        local beaconLight = beaconLight + 1
                        z = z + 1
                        local linkNode = createTransformGroup("linkNode")
                        link(rootNode, linkNode)
                        setTranslation(linkNode, x, 1, z)
                        setRotation(linkNode, 0, 3.141592653589793, 0)
                        local beaconLight = BeaconLight.new(nil)
                        beaconLight:setXMLSettings(nil, nil, mountType, variationName)
                        beaconLight:setRealLight(false)
                        beaconLight:setCallback(function(success)
                            -- upvalues: (ref) _, (ref) numLightsSuccess, (copy) beaconLight, (ref) numLightsFailed, (ref) beaconLight
                            _ = _ - 1
                            if success then
                                table.insert(BeaconLight.debugBeaconLights, beaconLight)
                            else
                                beaconLight:delete()
                            end
                            if _ == 0 then
                                for _, light in ipairs(BeaconLight.debugBeaconLights) do
                                    light:setIsActive(true)
                                end
                                Logging.info("%d Beacon lights: %d loaded, %d failed to load", beaconLight, numLightsSuccess, numLightsFailed)
                            end
                        end)
                        if beaconLight:loadFromXML(linkNode, filename, "") then
                            local wx, wy, wz = localToWorld(linkNode, 0, 0, -0.2)
                            local rx, ry, rz = localRotationToWorld(linkNode, -1.5707963267948966, 0, 0)
                            g_debugManager:addElement(DebugText3D.new():createWithWorldPos(wx, wy, wz, rx, ry, rz, string.format("%s (%s, %s)", file.filename, mountType, variationName), 0.07), nil, nil, math.huge)
                            g_debugManager:addElement(DebugGizmo.new():createWithNode(linkNode, "", nil, nil, 0.1), nil, nil, math.huge)
                        end
                    end
                end
                tempXMLFile:delete()
            end
        end
    end
end
function BeaconLight.registerXMLPaths(schema)
    schema:register(XMLValueType.STRING, "beaconLight.filename", "Path to i3d file", nil, true)
    schema:register(XMLValueType.NODE_INDEX, "beaconLight.rootNode#node", "Root node")
    schema:register(XMLValueType.STRING, "beaconLight.mountTypes.mountType(?)#name", "Name of the mount type")
    schema:register(XMLValueType.NODE_INDEX, "beaconLight.mountTypes.mountType(?)#node", "Node to show while this mount type is used")
    schema:register(XMLValueType.FLOAT, "beaconLight.mountTypes.mountType(?)#yOffset", "Y translation offset of the while beacon light while this mount type is used", 0)
    BeaconLight.registerVariationPaths(schema, "beaconLight")
    schema:register(XMLValueType.STRING, "beaconLight.variations.variation(?)#name", "Name of the variation")
    schema:register(XMLValueType.NODE_INDEX, "beaconLight.variations.variation(?)#rootNode", "Node that contains the variation data. Will be deleted if not used.")
    BeaconLight.registerVariationPaths(schema, "beaconLight.variations.variation(?)")
    I3DUtil.registerI3dMappingXMLPaths(schema, "beaconLight")
end
function BeaconLight.registerVariationPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rotator#node", "Node that is rotating")
    schema:register(XMLValueType.FLOAT, basePath .. ".rotator#speed", "Rotating speed", 0.015)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".staticLight(?)#node", "Light control shader node")
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#intensity", "Light intensity of shader node", 100)
    schema:register(XMLValueType.BOOL, basePath .. ".staticLight(?)#multiBlink", "Uses multiblink functionality", false)
    schema:register(XMLValueType.VECTOR_4, basePath .. ".staticLight(?)#multiBlinkParameters", "Parameters for multi blink function (blink ticks, pause ticks, frequency)", "2 5 50 0")
    schema:register(XMLValueType.INT, basePath .. ".staticLight(?)#uvOffsetParameter", "Parameter for light UV offset bit mask", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#minDistance", "Starting from this camera distance to static light is visible", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minDistance", "Reference distance for default intensity")
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minIntensity", "Intensity to be used at min. distance")
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxDistance", "Reference distance for max intensity")
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxIntensity", "Intensity to be used at max. distance")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".realLight#node", "Real light source node")
    schema:register(XMLValueType.BOOL, basePath .. ".realLight#useRealLight", "Defines if the real light is used at all for this variation", true)
    VehicleMaterial.registerXMLPaths(schema, basePath .. ".material")
    BeaconLightManager.registerXMLPaths(schema, basePath .. ".device")
end
function BeaconLight.registerVehicleXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Link node")
    schema:register(XMLValueType.FILENAME, basePath .. "#filename", "Beacon light xml file")
    schema:register(XMLValueType.FLOAT, basePath .. "#speed", "Beacon light speed override")
    schema:register(XMLValueType.BOOL, basePath .. "#useRealLights", "Use the real lights from the external beacon light file", true)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#realLight", "Custom real light to be used from the vehicle file instead of the external beacon light file")
    schema:register(XMLValueType.FLOAT, basePath .. "#realLightRange", "Factor that is applied on real light range of the beacon light", 1)
    schema:register(XMLValueType.INT, basePath .. "#intensity", "Beacon light intensity scale", 1)
    schema:register(XMLValueType.STRING, basePath .. "#mountType", "Name of the mount type to use (SURFACE or POLE for most of the beacon lights)")
    schema:register(XMLValueType.STRING, basePath .. "#variationName", "Name of the variation to use (ROTATE or BLINK for most of the beacon lights)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".staticLight(?)#node", "Static light node inside the vehicle i3d file")
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#intensity", "Intensity of this static light node", 100)
    schema:register(XMLValueType.BOOL, basePath .. ".staticLight(?)#multiBlink", "Uses multiblink functionality", false)
    schema:register(XMLValueType.VECTOR_4, basePath .. ".staticLight(?)#multiBlinkParameters", "Parameters for multi blink function (blink ticks, pause ticks, frequency)", "2 5 50 0")
    schema:register(XMLValueType.INT, basePath .. ".staticLight(?)#uvOffsetParameter", "Parameter for light UV offset bit mask", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?)#minDistance", "Starting from this camera distance to static light is visible", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minDistance", "Reference distance for default intensity", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#minIntensity", "Intensity to be used at min. distance", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxDistance", "Reference distance for max intensity", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".staticLight(?).intensityScale#maxIntensity", "Intensity to be used at max. distance", 0)
end
g_xmlManager:addCreateSchemaFunction(function()
    BeaconLight.xmlSchema = XMLSchema.new("beaconLight")
end)
g_xmlManager:addInitSchemaFunction(function()
    BeaconLight.registerXMLPaths(BeaconLight.xmlSchema)
end)