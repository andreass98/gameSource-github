StaticLightCompound = {}
source("dataS/scripts/vehicles/specializations/components/StaticLightCompoundUVSlot.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLightCompoundLightType.lua")
local StaticLightCompound_mt = Class(StaticLightCompound)
function StaticLightCompound.new(vehicle, customMt)
    -- upvalues: (copy) StaticLightCompound_mt
    local self = setmetatable({}, customMt or StaticLightCompound_mt)
    self.vehicle = vehicle
    return self
end
function StaticLightCompound.loadFunctionMappingData(xmlFile, baseKey)
    local data = {}
    for _, functionKey in xmlFile:iterator(baseKey .. ".function") do
        local functionName = xmlFile:getValue(functionKey .. "#name")
        if functionName == nil then
            Logging.xmlWarning(xmlFile, "Missing function name in \'%s\'", functionKey)
        else
            local defaultSlotIndex = StaticLightCompoundUVSlot.getByName(functionName)
            if defaultSlotIndex == nil then
                Logging.xmlWarning(xmlFile, "Invalid function name \'%s\' in \'%s\'", functionName, functionKey)
            else
                local uvSlotIndex = xmlFile:getValue(functionKey .. "#uvSlotIndex", defaultSlotIndex)
                if uvSlotIndex >= 1 and uvSlotIndex <= 16 then
                    local uvOffset = xmlFile:getValue(functionKey .. "#uvOffset", 0)
                    local intensityScale = xmlFile:getValue(functionKey .. "#intensityScale", 1)
                    local lightTypeStr = xmlFile:getValue(functionKey .. "#lightType")
                    table.insert(data, {
                        ["defaultSlotIndex"] = defaultSlotIndex,
                        ["uvSlotIndex"] = uvSlotIndex,
                        ["uvOffset"] = uvOffset,
                        ["intensityScale"] = intensityScale,
                        ["lightTypeIndex"] = StaticLightCompoundLightType.getByName(lightTypeStr)
                    })
                else
                    Logging.xmlWarning(xmlFile, "UV slot index out of range \'%d\' in \'%s\'. Range 1-16 is allowed.", uvSlotIndex, functionKey)
                end
            end
        end
    end
    return data
end
function StaticLightCompound:loadFromXML(xmlFile, baseKey, components, i3dMappings, vehicle, sharedLight)
    self.bottomLightAsHighBeam = xmlFile:getValue(baseKey .. "#bottomLightAsHighBeam", true)
    self.topLightAsHighBeam = xmlFile:getValue(baseKey .. "#topLightAsHighBeam", true)
    self.useSliderTurnLights = xmlFile:getValue(baseKey .. "#useSliderTurnLights", false)
    self.intensity = {}
    self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] = 1.4
    self.intensity[StaticLightCompoundUVSlot.DAY_TIME_RUNNING_LIGHT] = 0.4
    self.funcToUVSlotMapping = {}
    local index = 1
    for index = index, 16 do
        self.funcToUVSlotMapping[index] = {}
    end
    for i, mappingData in ipairs((StaticLightCompound.loadFunctionMappingData(xmlFile, baseKey))) do
        table.insert(self.funcToUVSlotMapping[mappingData.defaultSlotIndex], mappingData)
    end
    if sharedLight ~= nil and sharedLight.functionMappingData ~= nil then
        for i, mappingData in ipairs(sharedLight.functionMappingData) do
            for mappedFuncIndex, mappedSlots in pairs(self.funcToUVSlotMapping) do
                local i = #mappedSlots
                for i = i, 1, -1 do
                    if mappedSlots[i].uvSlotIndex == mappingData.uvSlotIndex then
                        table.remove(mappedSlots, i)
                    end
                end
            end
        end
        for i, mappingData in ipairs(sharedLight.functionMappingData) do
            table.insert(self.funcToUVSlotMapping[mappingData.defaultSlotIndex], mappingData)
        end
    end
    local index = 1
    local index = 1
    for index = index, 16, index do
        local i = false
        for mappedFuncIndex, mappedFuncIndex in pairs(self.funcToUVSlotMapping) do
            for i, mappedSlot in pairs(mappedFuncIndex) do
                if mappedSlot.uvSlotIndex == index then
                    i = true
                    break
                end
            end
            if i then
                break
            end
        end
        if not i then
            table.insert(self.funcToUVSlotMapping[index], {
                ["uvSlotIndex"] = index,
                ["uvOffset"] = 0,
                ["intensityScale"] = 1
            })
        end
    end
    self.nodes = {}
    for i, mappingData in xmlFile:iterator(baseKey .. ".node") do
        local node = xmlFile:getValue(mappingData .. "#node", nil, components, i3dMappings)
        if node == nil then
            Logging.xmlWarning(xmlFile, "Invalid node in \'%s\'", mappingData)
        else
            if sharedLight == nil then
                goto l40
            end
            local isValid = false
            while node ~= nil and (node ~= 0 and node ~= getRootNode()) do
                if node == sharedLight.node then
                    isValid = true
                    break
                end
                node = getParent(node)
            end
            if isValid then
                ::l40::
                if getHasClassId(node, ClassIds.LIGHT_SOURCE) then
                    Logging.xmlWarning(xmlFile, "Light source used in static light compound in \'%s\'", mappingData)
                elseif getHasClassId(node, ClassIds.SHAPE) then
                    if getHasShaderParameter(node, "lightIds0") then
                        setShaderParameter(node, "lightIds0", 0, 0, 0, 0, false)
                        setShaderParameter(node, "lightIds1", 0, 0, 0, 0, false)
                        setShaderParameter(node, "lightIds2", 0, 0, 0, 0, false)
                        setShaderParameter(node, "lightIds3", 0, 0, 0, 0, false)
                        local isValid = {
                            ["node"] = node,
                            ["intensity"] = xmlFile:getValue(mappingData .. "#intensity", 5),
                            ["useSliderTurnLights"] = xmlFile:getValue(mappingData .. "#useSliderTurnLights", self.useSliderTurnLights)
                        }
                        if vehicle ~= nil and xmlFile:getRootName() == "vehicle" then
                            vehicle:loadAdditionalLightAttributesFromXML(xmlFile, mappingData, isValid)
                        end
                        if sharedLight ~= nil and sharedLight.additionalAttributes ~= nil then
                            for k, v in pairs(sharedLight.additionalAttributes) do
                                isValid[k] = v
                            end
                        end
                        local mappedFuncIndex = self.nodes
                        table.insert(mappedFuncIndex, isValid)
                    else
                        Logging.xmlWarning(xmlFile, "Wrong shader applied to static light compound in \'%s\'. Missing \'lightIds\' shader parameter.", mappingData)
                    end
                else
                    Logging.xmlWarning(xmlFile, "Node used in static light compound in \'%s\' is not a shape", mappingData)
                end
            else
                Logging.xmlWarning(xmlFile, "Static compound light mesh \'%s\' is outside of the root shared light node (%s) in \'%s\'", getName(node), getName(sharedLight.node), baseKey)
            end
        end
    end
    if #self.nodes == 0 then
        Logging.xmlWarning(xmlFile, "Missing nodes for static light compound in \'%s\'", baseKey)
        return false
    end
    self.states = {}
    self.stateFuncTypes = {}
    self.stateLightTypes = {}
    self.stateUVOffsets = {}
    local index = 1
    local index = 1
    for index = index, 16, index do
        table.insert(self.states, 0)
        table.insert(self.stateFuncTypes, 0)
        table.insert(self.stateLightTypes, -1)
        table.insert(self.stateUVOffsets, 0)
    end
    return true
end
function StaticLightCompound:setLightTypes(lightTypes, excludedLightTypes)
    if lightTypes ~= nil and next(lightTypes) ~= nil then
        self.lightTypes = lightTypes
    end
    if excludedLightTypes ~= nil and next(excludedLightTypes) ~= nil then
        self.excludedLightTypes = excludedLightTypes
    end
end
function StaticLightCompound:setOverwriteSettings(turnLightLeft, turnLightRight, reverseLight)
    self.turnLightLeft = turnLightLeft
    self.turnLightRight = turnLightRight
    self.reverseLight = reverseLight
    if turnLightLeft then
        if self.lightTypes == nil then
            self.lightTypes = {}
        end
        table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightLeft)
        table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightAny)
    end
    if turnLightRight then
        if self.lightTypes == nil then
            self.lightTypes = {}
        end
        table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightRight)
        table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.turnLightAny)
    end
    if reverseLight then
        if self.lightTypes == nil then
            self.lightTypes = {}
        end
        table.insert(self.lightTypes, self.vehicle.spec_lights.additionalLightTypes.reverseLight)
    end
end
function StaticLightCompound:setLightTypesMask(lightsTypesMask, vehicle)
    local startIndex = 1
    if self.lightTypes ~= nil then
        local isActive = false
        for _, lightType in pairs(self.lightTypes) do
            if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 then
                isActive = true
                break
            end
        end
        if isActive and self.excludedLightTypes ~= nil then
            for _, lightType in pairs(self.excludedLightTypes) do
                if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 then
                    isActive = false
                    break
                end
            end
        end
        local lightUvOffsetBitMask = self.states
        local index = isActive and 1 or 0
        lightUvOffsetBitMask[1] = index
        if self.turnLightLeft then
            self.stateFuncTypes[1] = StaticLightCompoundUVSlot.TURN_LIGHT_LEFT
        elseif self.turnLightRight then
            self.stateFuncTypes[1] = StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT
        end
        startIndex = 2
    end
    local isActive = 16
    local lightUvOffsetBitMask = 1
    for startIndex = startIndex, isActive, lightUvOffsetBitMask do
        self.states[startIndex] = 0
        self.stateFuncTypes[startIndex] = 0
        self.stateLightTypes[startIndex] = -1
        self.stateUVOffsets[startIndex] = 0
        for mappedFuncIndex, mappedSlots in pairs(self.funcToUVSlotMapping) do
            for _, mappedSlot in pairs(mappedSlots) do
                if mappedSlot.uvSlotIndex == startIndex then
                    local value = self:getStateValueByFunction(startIndex, mappedFuncIndex, lightsTypesMask, vehicle)
                    if value > 0 then
                        self.states[startIndex] = value * (self.intensity[mappedFuncIndex] or 1) * mappedSlot.intensityScale
                        if self.stateFuncTypes[startIndex] ~= StaticLightCompoundUVSlot.TURN_LIGHT_LEFT and self.stateFuncTypes[startIndex] ~= StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
                            self.stateFuncTypes[startIndex] = mappedFuncIndex
                        end
                        self.stateUVOffsets[startIndex] = mappedSlot.uvOffset
                        if mappedSlot.lightTypeIndex ~= nil then
                            self.stateLightTypes[startIndex] = mappedSlot.lightTypeIndex
                        end
                        break
                    end
                end
            end
        end
    end
    local isActive = self:getLightTypeMaskFromStates(self.useSliderTurnLights)
    local lightUvOffsetBitMask = self:getUVOffsetMaskFromStates()
    for lightType, mappedFuncIndex in ipairs(self.nodes) do
        if vehicle:getIsLightActive(mappedFuncIndex) then
            local mappedSlots = mappedFuncIndex.intensity
            setShaderParameter(mappedFuncIndex.node, "lightIds0", self.states[1] * mappedSlots, self.states[2] * mappedSlots, self.states[3] * mappedSlots, self.states[4] * mappedSlots, false)
            setShaderParameter(mappedFuncIndex.node, "lightIds1", self.states[5] * mappedSlots, self.states[6] * mappedSlots, self.states[7] * mappedSlots, self.states[8] * mappedSlots, false)
            setShaderParameter(mappedFuncIndex.node, "lightIds2", self.states[9] * mappedSlots, self.states[10] * mappedSlots, self.states[11] * mappedSlots, self.states[12] * mappedSlots, false)
            setShaderParameter(mappedFuncIndex.node, "lightIds3", self.states[13] * mappedSlots, self.states[14] * mappedSlots, self.states[15] * mappedSlots, self.states[16] * mappedSlots, false)
            if self.useSliderTurnLights == mappedFuncIndex.useSliderTurnLights then
                setShaderParameter(mappedFuncIndex.node, "lightTypeBitMask", isActive, nil, nil, nil, false)
            else
                local nodeLightTypesMask = self:getLightTypeMaskFromStates(mappedFuncIndex.useSliderTurnLights)
                setShaderParameter(mappedFuncIndex.node, "lightTypeBitMask", nodeLightTypesMask, nil, nil, nil, false)
            end
            setShaderParameter(mappedFuncIndex.node, "lightUvOffsetBitMask", lightUvOffsetBitMask, nil, nil, nil, false)
        else
            setShaderParameter(mappedFuncIndex.node, "lightIds0", 0, 0, 0, 0, false)
            setShaderParameter(mappedFuncIndex.node, "lightIds1", 0, 0, 0, 0, false)
            setShaderParameter(mappedFuncIndex.node, "lightIds2", 0, 0, 0, 0, false)
            setShaderParameter(mappedFuncIndex.node, "lightIds3", 0, 0, 0, 0, false)
        end
    end
end
function StaticLightCompound:getStateValueByFunction(_, funcIndex, lightsTypesMask, vehicle)
    local highBeamActive = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM) ~= 0
    local value = 0
    if funcIndex == StaticLightCompoundUVSlot.DEFAULT_LIGHT then
        local chargeScale = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) == 0 and 0 or 1
        return chargeScale
    end
    if funcIndex ~= StaticLightCompoundUVSlot.DEFAULT_LIGHT_HIGH_BEAM then
        if funcIndex == StaticLightCompoundUVSlot.HIGH_BEAM then
            return highBeamActive and 1 or 0
        end
        if funcIndex == StaticLightCompoundUVSlot.BOTTOM_LIGHT then
            value = bit32.band(lightsTypesMask, 2 ^ vehicle.spec_lights.additionalLightTypes.bottomLight) == 0 and 0 or 1
            if self.bottomLightAsHighBeam and (not spec.topLightsVisibility and highBeamActive) then
                return math.max(value, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
            end
        else
            if funcIndex ~= StaticLightCompoundUVSlot.TOP_LIGHT then
                if funcIndex == StaticLightCompoundUVSlot.DAY_TIME_RUNNING_LIGHT then
                    local chargeScale = (vehicle:getIsPowered() or vehicle:getIsInShowroom()) and 1 or 0
                    return chargeScale
                end
                if funcIndex ~= StaticLightCompoundUVSlot.TURN_LIGHT_LEFT then
                    if funcIndex ~= StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
                        if funcIndex == StaticLightCompoundUVSlot.BACK_LIGHT then
                            local chargeScale = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) == 0 and 0 or 1
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.BRAKE_LIGHT then
                            local chargeScale = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.brakeLight) == 0 and 0 or 1
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.BACK_BRAKE_LIGHT then
                            local chargeScale = 0
                            if bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
                            end
                            if bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.brakeLight) ~= 0 then
                            end
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.REVERSE_LIGHT then
                            local chargeScale = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.reverseLight) == 0 and 0 or 1
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_FRONT then
                            local chargeScale = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT) == 0 and 0 or 1
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_BACK then
                            local chargeScale = bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_BACK) == 0 and 0 or 1
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_ADDITIONAL then
                            local chargeScale = bit32.band(lightsTypesMask, 2 ^ (Lights.LIGHT_TYPE_HIGHBEAM + 1)) == 0 and 0 or 1
                            return chargeScale
                        end
                        if funcIndex == StaticLightCompoundUVSlot.WORK_LIGHT_ADDITIONAL2 then
                            value = bit32.band(lightsTypesMask, 2 ^ (Lights.LIGHT_TYPE_HIGHBEAM + 2)) == 0 and 0 or 1
                        end
                        goto l16
                    end
                    if bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightRight) == 0 then
                        if bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightAny) == 0 then
                            chargeScale = 0
                            goto l55
                        end
                    end
                    local chargeScale = 1
                    ::l55::
                    return chargeScale
                end
                if bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightLeft) == 0 then
                    if bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightAny) == 0 then
                        chargeScale = 0
                        goto l49
                    end
                end
                local chargeScale = 1
                ::l49::
                return chargeScale
            end
            value = bit32.band(lightsTypesMask, 2 ^ spec.additionalLightTypes.topLight) == 0 and 0 or 1
            if self.topLightAsHighBeam and (spec.topLightsVisibility and highBeamActive) then
                return math.max(value, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
            end
        end
        ::l16::
        return value
    end
    if not highBeamActive then
        if bit32.band(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) == 0 then
            value = 0
            goto l14
        end
    end
    value = 1
    ::l14::
    if highBeamActive then
        return math.max(value, 1) * (self.intensity[StaticLightCompoundUVSlot.HIGH_BEAM] or 2)
    end
    goto l16
end
function StaticLightCompound:getLightTypeMaskFromStates(slider)
    local mask = 0
    local index = 1
    for index = index, 12 do
        local funcIndex = self.stateFuncTypes[index]
        local type = nil
        if funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_LEFT or funcIndex == StaticLightCompoundUVSlot.TURN_LIGHT_RIGHT then
            type = slider and StaticLightCompoundLightType.SLIDE or StaticLightCompoundLightType.BLINKING
        end
        if self.stateLightTypes[index] ~= -1 then
            type = self.stateLightTypes[index]
        end
        if type ~= nil then
            mask = bit32.bor(bit32.lshift(type - 1, (index - 1) * 2), mask)
        end
    end
    return mask
end
function StaticLightCompound:getUVOffsetMaskFromStates()
    local mask = bit32.bor(bit32.lshift(self.stateUVOffsets[1], 0), 0)
    local mask = bit32.bor(bit32.lshift(self.stateUVOffsets[2], 6), mask)
    local mask = bit32.bor(bit32.lshift(self.stateUVOffsets[3], 12), mask)
    return bit32.bor(bit32.lshift(self.stateUVOffsets[4], 18), mask)
end
function StaticLightCompound.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#bottomLightAsHighBeam", "Use bottom light as high beam as well", true)
    schema:register(XMLValueType.BOOL, basePath .. "#topLightAsHighBeam", "Use top light as high beam as well", true)
    schema:register(XMLValueType.BOOL, basePath .. "#useSliderTurnLights", "Turn lights will work as sliders if set to \'true\'", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Static light node")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#intensity", "Intensity for all lights in this node", 5)
    schema:register(XMLValueType.BOOL, basePath .. ".node(?)#useSliderTurnLights", "Turn lights will work as sliders if set to \'true\'", false)
    schema:register(XMLValueType.INT, basePath .. ".node(?)#lightTypeBitMask", "Custom light type bit mask")
    schema:register(XMLValueType.STRING, basePath .. ".function(?)#name", "Function name", nil, nil, StaticLightCompoundUVSlot.getAllOrderedByName())
    schema:register(XMLValueType.INT, basePath .. ".function(?)#uvSlotIndex", "Custom UV slot index to assign the defined function name")
    schema:register(XMLValueType.INT, basePath .. ".function(?)#uvOffset", "Vertical UV offset that is used while this light function is active (value range: 0-64 -> this represents the height of the texture with a resolution of 1/64). This is used for double usage of certain lights with different colors.", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".function(?)#intensityScale", "Custom intensity scale for this light type (is multiplied by the intensity defined in the node)")
    schema:register(XMLValueType.STRING, basePath .. ".function(?)#lightType", "Name of the light type to use", nil, nil, StaticLightCompoundLightType.getAllOrderedByName())
    schema:register(XMLValueType.INT, basePath .. "#lightTypeBitMask", "Custom light type bit mask", "Default mask is \'20480\' with blinking type set for turn light slots 7 & 8")
end