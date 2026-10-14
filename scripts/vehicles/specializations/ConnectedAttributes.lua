ConnectedAttributes = {}
ConnectedAttributes.COMBINE_OPERATION = {}
ConnectedAttributes.COMBINE_OPERATION.AVERAGE = 0
ConnectedAttributes.COMBINE_OPERATION.SUM = 1
ConnectedAttributes.COMBINE_OPERATION.SUBTRACT = 2
ConnectedAttributes.COMBINE_OPERATION.MULTIPLY = 3
ConnectedAttributes.COMBINE_OPERATION.DIVIDE = 4
function ConnectedAttributes.prerequisitesPresent(specializations)
    return true
end
function ConnectedAttributes.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ConnectedAttributes")
    schema:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?)#isActiveDirty", "Attribute is permanently updated", false)
    schema:register(XMLValueType.FLOAT, "vehicle.connectedAttributes.attribute(?)#maxUpdateDistance", "If the player is within this distance to the vehicle, the attribute is updated", "always")
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#name", "Name of animation that triggers a update of the connected value")
    schema:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#onStart", "Update is triggered on start of the animation", false)
    schema:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#onRun", "Update is triggered while the animation is running", false)
    schema:register(XMLValueType.BOOL, "vehicle.connectedAttributes.attribute(?).updateByAnimation(?)#onStop", "Update is triggered while the animation is stopped", false)
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).prerequisites.animation(?)#name", "Name of animation that needs to be in the defined target range")
    schema:register(XMLValueType.FLOAT, "vehicle.connectedAttributes.attribute(?).prerequisites.animation(?)#minTime", "Min. time of animation", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.connectedAttributes.attribute(?).prerequisites.animation(?)#maxTime", "Max. time of animation", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.connectedAttributes.attribute(?).source(?)#node", "Source reference node")
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).source(?)#type", "Source type (" .. ConnectedAttributes.TYPES_STRING .. ")", nil, nil, table.toList(ConnectedAttributes.TYPES_BY_NAME))
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).source(?)#values", "Value definition from the source")
    local i = 1
    for i = i, #ConnectedAttributes.TYPES do
        ConnectedAttributes.TYPES[i].registerSourceXMLPaths(schema, "vehicle.connectedAttributes.attribute(?).source(?)")
    end
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).combine(?)#value", "New value id of the combined value")
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).combine(?)#operation", "Operation to be executed on the values (AVERAGE, SUM, SUBTRACT, MULTIPLY, DIVIDE)")
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).combine(?)#values", "Values to combine")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.connectedAttributes.attribute(?).target(?)#node", "Target reference node")
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).target(?)#type", "Target type (" .. ConnectedAttributes.TYPES_STRING .. ")", nil, nil, table.toList(ConnectedAttributes.TYPES_BY_NAME))
    schema:register(XMLValueType.STRING, "vehicle.connectedAttributes.attribute(?).target(?)#values", "Value definition how the source values are applied to the target")
    local i = 1
    for i = i, #ConnectedAttributes.TYPES do
        ConnectedAttributes.TYPES[i].registerTargetXMLPaths(schema, "vehicle.connectedAttributes.attribute(?).target(?)")
    end
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#connectedAttributeIndices", "Connected attributes to update")
    end)
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#connectedAttributeIndices", "Connected attributes to update")
    end)
    schema:setXMLSpecializationType()
end
function ConnectedAttributes.registerFunctions(vehicleType) end
function ConnectedAttributes.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ConnectedAttributes.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ConnectedAttributes.updateExtraDependentParts)
end
function ConnectedAttributes.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onPlayAnimation", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateAnimation", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", ConnectedAttributes)
end
function ConnectedAttributes:onLoad(_)
    local spec = self.spec_connectedAttributes
    spec.attributes = {}
    spec.dirtyAttributes = {}
    local hasOnStart = false
    local hasOnRun = false
    local hasOnStop = false
    self.xmlFile:iterate("vehicle.connectedAttributes.attribute", function(_, attributeKey)
        -- upvalues: (copy) self, (ref) hasOnStart, (ref) hasOnRun, (ref) hasOnStop, (copy) spec
        local attribute = {
            ["isActive"] = false,
            ["isActiveDirty"] = self.xmlFile:getValue(attributeKey .. "#isActiveDirty", false),
            ["maxUpdateDistance"] = self.xmlFile:getValue(attributeKey .. "#maxUpdateDistance"),
            ["values"] = {},
            ["updateByAnimations"] = {}
        }
        self.xmlFile:iterate(attributeKey .. ".updateByAnimation", function(_, animationKey)
            -- upvalues: (ref) self, (copy) attribute, (ref) hasOnStart, (ref) hasOnRun, (ref) hasOnStop
            local updateByAnimationData = {
                ["animationName"] = self.xmlFile:getValue(animationKey .. "#name")
            }
            if updateByAnimationData.animationName ~= nil then
                updateByAnimationData.onStart = self.xmlFile:getValue(animationKey .. "#onStart", false)
                updateByAnimationData.onRun = self.xmlFile:getValue(animationKey .. "#onRun", false)
                updateByAnimationData.onStop = self.xmlFile:getValue(animationKey .. "#onStop", false)
                if updateByAnimationData.onStart or (updateByAnimationData.onRun or updateByAnimationData.onStop) then
                    table.insert(attribute.updateByAnimations, updateByAnimationData)
                end
            end
        end)
        attribute.prerequisites = {}
        self.xmlFile:iterate(attributeKey .. ".prerequisites.animation", function(_, animationKey)
            -- upvalues: (ref) self, (copy) attribute
            local animationName = self.xmlFile:getValue(animationKey .. "#name")
            local minTime = self.xmlFile:getValue(animationKey .. "#minTime", 0)
            local maxTime = self.xmlFile:getValue(animationKey .. "#maxTime", 1)
            if animationName ~= nil and (minTime > 0 or maxTime < 1) then
                table.insert(attribute.prerequisites, function()
                    -- upvalues: (ref) self, (copy) animationName, (copy) minTime, (copy) maxTime
                    local t = self:getAnimationTime(animationName)
                    return minTime <= t and t <= maxTime
                end)
            end
        end)
        attribute.sources = {}
        self.xmlFile:iterate(attributeKey .. ".source", function(_, sourceKey)
            -- upvalues: (ref) self, (copy) attribute
            local source = {
                ["node"] = self.xmlFile:getValue(sourceKey .. "#node", nil, self.components, self.i3dMappings)
            }
            if source.node == nil then
                Logging.xmlWarning(self.xmlFile, "Missing node in \'%s\'", sourceKey)
                return
            else
                local typeString = self.xmlFile:getValue(sourceKey .. "#type")
                if typeString == nil then
                    Logging.xmlWarning(self.xmlFile, "Missing type in \'%s\'", sourceKey)
                    return
                else
                    source.typeClass = ConnectedAttributes.TYPES_BY_NAME[string.upper(typeString)]
                    if source.typeClass == nil then
                        Logging.xmlWarning(self.xmlFile, "Invalid type \'%s\' in \'%s\'", typeString, sourceKey)
                        return
                    elseif source.typeClass.isAvailable == nil or source.typeClass.isAvailable(self) then
                        source.object = source.typeClass.new(self, source.node, self.xmlFile, sourceKey, self.components, self.i3dMappings)
                        if source.object == nil then
                            Logging.xmlWarning(self.xmlFile, "Failed to load source \'%s\'", sourceKey)
                        else
                            source.values = {}
                            local valuesStr = self.xmlFile:getValue(sourceKey .. "#values")
                            if valuesStr ~= nil then
                                local valueParts = valuesStr:split(" ")
                                local i = 1
                                for i = i, math.min(#valueParts, source.typeClass.NUM_VALUES) do
                                    if valueParts[i] ~= "-" then
                                        source.values[i] = valueParts[i]
                                        attribute.values[valueParts[i]] = 0
                                    end
                                end
                            end
                            table.insert(attribute.sources, source)
                        end
                    else
                        return
                    end
                end
            end
        end)
        attribute.combinations = {}
        self.xmlFile:iterate(attributeKey .. ".combine", function(_, combineKey)
            -- upvalues: (ref) self, (copy) attribute
            local combination = {
                ["value"] = self.xmlFile:getValue(combineKey .. "#value")
            }
            if combination.value == nil then
                Logging.xmlWarning(self.xmlFile, "Missing value for \'%s\'", combineKey)
                return
            else
                local operationStr = self.xmlFile:getValue(combineKey .. "#operation")
                if operationStr ~= nil then
                    combination.operation = ConnectedAttributes.COMBINE_OPERATION[string.upper(operationStr)]
                end
                if combination.operation == nil then
                    Logging.xmlWarning(self.xmlFile, "Invalid operation for \'%s\'", combineKey)
                    return
                else
                    combination.values = {}
                    local valuesStr = self.xmlFile:getValue(combineKey .. "#values")
                    if valuesStr ~= nil then
                        local valueParts = valuesStr:split(" ")
                        local i = 1
                        for i = i, #valueParts do
                            local valueId = valueParts[i]
                            if valueId ~= "" and attribute.values[valueId] ~= nil then
                                table.insert(combination.values, valueId)
                            end
                        end
                    end
                    combination.numValues = #combination.values
                    if combination.numValues == 0 then
                        Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", combineKey)
                    else
                        attribute.values[combination.value] = 0
                        table.insert(attribute.combinations, combination)
                    end
                end
            end
        end)
        attribute.targets = {}
        self.xmlFile:iterate(attributeKey .. ".target", function(_, targetKey)
            -- upvalues: (ref) self, (copy) attribute
            local target = {
                ["node"] = self.xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
            }
            if target.node == nil then
                Logging.xmlWarning(self.xmlFile, "Missing node in \'%s\'", targetKey)
                return
            else
                local typeString = self.xmlFile:getValue(targetKey .. "#type")
                if typeString == nil then
                    Logging.xmlWarning(self.xmlFile, "Missing type in \'%s\'", targetKey)
                    return
                else
                    target.typeClass = ConnectedAttributes.TYPES_BY_NAME[string.upper(typeString)]
                    if target.typeClass == nil then
                        Logging.xmlWarning(self.xmlFile, "Invalid type \'%s\' in \'%s\'", typeString, targetKey)
                        return
                    elseif target.typeClass.isAvailable == nil or target.typeClass.isAvailable(self) then
                        target.object = target.typeClass.new(self, target.node, self.xmlFile, targetKey, self.components, self.i3dMappings)
                        if target.object == nil then
                            Logging.xmlWarning(self.xmlFile, "Failed to load target \'%s\'", targetKey)
                        else
                            target.object:get()
                            target.values = {}
                            target.factors = {}
                            target.additionals = {}
                            target.toSourceValue = {}
                            local valuesStr = self.xmlFile:getValue(targetKey .. "#values")
                            if valuesStr ~= nil then
                                local valueParts = valuesStr:split(" ")
                                local i = 1
                                local singleValueParts = math.min(#valueParts, target.typeClass.NUM_VALUES)
                                for i = i, singleValueParts do
                                    if valueParts[i] ~= "-" then
                                        if valueParts[i]:contains("*") then
                                            local singleValueParts = valueParts[i]:split("*")
                                            target.values[i] = singleValueParts[1]
                                            target.factors[i] = tonumber(singleValueParts[2]) or 1
                                            target.additionals[i] = 0
                                        elseif valueParts[i]:contains("/") then
                                            local singleValueParts = valueParts[i]:split("/")
                                            target.values[i] = singleValueParts[1]
                                            target.factors[i] = 1 / (tonumber(singleValueParts[2]) or 1)
                                            target.additionals[i] = 0
                                        elseif valueParts[i]:contains("+") then
                                            local singleValueParts = valueParts[i]:split("+")
                                            target.values[i] = singleValueParts[1]
                                            target.factors[i] = 1
                                            target.additionals[i] = tonumber(singleValueParts[2]) or 0
                                        elseif valueParts[i]:contains("-") then
                                            local singleValueParts = valueParts[i]:split("-")
                                            if singleValueParts[1] == "" then
                                                if attribute.values[singleValueParts[2]] == nil then
                                                    target.values[i] = next(attribute.values)
                                                    target.factors[i] = 0
                                                    target.additionals[i] = tonumber(valueParts[i])
                                                else
                                                    target.values[i] = singleValueParts[2]
                                                    target.factors[i] = -1
                                                    target.additionals[i] = 0
                                                end
                                            else
                                                target.values[i] = singleValueParts[1]
                                                target.factors[i] = 1
                                                target.additionals[i] = -(tonumber(singleValueParts[2]) or 0)
                                            end
                                        elseif attribute.values[valueParts[i]] == nil then
                                            if tonumber(valueParts[i]) ~= nil then
                                                target.values[i] = next(attribute.values)
                                                target.factors[i] = 0
                                                target.additionals[i] = tonumber(valueParts[i])
                                            end
                                        else
                                            target.values[i] = valueParts[i]
                                            target.factors[i] = 1
                                            target.additionals[i] = 0
                                        end
                                        if target.values[i] == nil or (target.values[i] == "" or attribute.values[target.values[i]] == nil) then
                                            target.values[i] = nil
                                            target.factors[i] = nil
                                            target.additionals[i] = nil
                                            Logging.xmlWarning(self.xmlFile, "Failed to validate target value \'%s\' of \'%s\' in \'%s\'", valueParts[i], valuesStr, targetKey)
                                        else
                                            target.toSourceValue[i] = attribute.values[target.values[i]]
                                        end
                                    end
                                end
                            end
                            table.insert(attribute.targets, target)
                        end
                    else
                        return
                    end
                end
            end
        end)
        if #attribute.sources >= 1 and #attribute.targets >= 1 then
            table.insert(spec.attributes, attribute)
            if attribute.isActiveDirty then
                table.insert(spec.dirtyAttributes, attribute)
            end
        end
    end)
    if #spec.attributes == 0 then
        SpecializationUtil.removeEventListener(self, "onLoadFinished", ConnectedAttributes)
        SpecializationUtil.removeEventListener(self, "onUpdate", ConnectedAttributes)
    elseif #spec.dirtyAttributes == 0 then
        SpecializationUtil.removeEventListener(self, "onUpdate", ConnectedAttributes)
    end
    if not hasOnStart then
        SpecializationUtil.removeEventListener(self, "onPlayAnimation", ConnectedAttributes)
    end
    if not hasOnRun then
        SpecializationUtil.removeEventListener(self, "onUpdateAnimation", ConnectedAttributes)
    end
    if not hasOnStop then
        SpecializationUtil.removeEventListener(self, "onFinishAnimation", ConnectedAttributes)
    end
end
function ConnectedAttributes:onLoadFinished(_)
    for _, attribute in ipairs(self.spec_connectedAttributes.attributes) do
        ConnectedAttributes.updateAttribute(attribute, true)
    end
end
function ConnectedAttributes:onUpdate(_, _, _, _)
    local spec = self.spec_connectedAttributes
    local i = 1
    for i = i, #spec.dirtyAttributes do
        local attribute = spec.dirtyAttributes[i]
        if attribute.maxUpdateDistance == nil or self.currentUpdateDistance < attribute.maxUpdateDistance then
            ConnectedAttributes.updateAttribute(attribute)
        end
    end
end
function ConnectedAttributes:onUpdateEnd(_, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    ConnectedAttributes.onUpdate(self, 99999, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end
function ConnectedAttributes:onPlayAnimation(animationName)
    for _, attribute in ipairs(self.spec_connectedAttributes.attributes) do
        for _, updateByAnimationData in ipairs(attribute.updateByAnimations) do
            if updateByAnimationData.onStart and updateByAnimationData.animationName == animationName then
                ConnectedAttributes.updateAttribute(attribute, true)
                break
            end
        end
    end
end
function ConnectedAttributes:onUpdateAnimation(animationName)
    for _, attribute in ipairs(self.spec_connectedAttributes.attributes) do
        for _, updateByAnimationData in ipairs(attribute.updateByAnimations) do
            if updateByAnimationData.onRun and updateByAnimationData.animationName == animationName then
                ConnectedAttributes.updateAttribute(attribute, true)
                break
            end
        end
    end
end
function ConnectedAttributes:onFinishAnimation(animationName)
    for _, attribute in ipairs(self.spec_connectedAttributes.attributes) do
        for _, updateByAnimationData in ipairs(attribute.updateByAnimations) do
            if updateByAnimationData.onStop and updateByAnimationData.animationName == animationName then
                ConnectedAttributes.updateAttribute(attribute, true)
                break
            end
        end
    end
end
function ConnectedAttributes.updateAttribute(attribute, forceUpdate)
    local isActive = true
    local i = 1
    local values = #attribute.prerequisites
    local hasChanged = 1
    for i = i, values, hasChanged do
        if not attribute.prerequisites[i]() then
            isActive = false
            break
        end
    end
    if isActive then
        local hasChanged = attribute.isActive ~= isActive and true or forceUpdate
        local sourceIndex = 1
        local i = #attribute.sources
        for sourceIndex = sourceIndex, i do
            local source = attribute.sources[sourceIndex]
            local object = source.object
            object:get()
            for index, name in pairs(source.values) do
                local value = object.data[index]
                if value ~= attribute.values[name] then
                    values[name] = value
                    hasChanged = true
                end
            end
        end
        local sourceIndex = 1
        local i = #attribute.combinations
        for sourceIndex = sourceIndex, i do
            local source = attribute.combinations[sourceIndex]
            if source.operation == ConnectedAttributes.COMBINE_OPERATION.AVERAGE then
                local object = 0
                local j = 1
                for j = j, source.numValues do

                end
                values[source.value] = object / source.numValues
            elseif source.operation == ConnectedAttributes.COMBINE_OPERATION.SUM then
                local object = 0
                local j = 1
                for j = j, source.numValues do

                end
                values[source.value] = object
            elseif source.operation == ConnectedAttributes.COMBINE_OPERATION.SUBTRACT then
                local object = values[source.values[1]]
                local j = 2
                for j = j, source.numValues do

                end
                values[source.value] = object
            elseif source.operation == ConnectedAttributes.COMBINE_OPERATION.MULTIPLY then
                local object = values[source.values[1]]
                local j = 2
                for j = j, source.numValues do

                end
                values[source.value] = object
            elseif source.operation == ConnectedAttributes.COMBINE_OPERATION.DIVIDE then
                local object = values[source.values[1]]
                local j = 2
                for j = j, source.numValues do

                end
                values[source.value] = object
            end
        end
        if hasChanged then
            local sourceIndex = 1
            for sourceIndex = sourceIndex, #attribute.targets do
                local source = attribute.targets[sourceIndex]
                local object = source.object
                for index, name in pairs(source.values) do
                    object.data[index] = values[name] * source.factors[index] + source.additionals[index]
                end
                object:set()
            end
        end
    end
    attribute.isActive = isActive
end
function ConnectedAttributes:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end
    local connectedAttributeIndices = xmlFile:getValue(baseName .. "#connectedAttributeIndices", nil, true)
    if connectedAttributeIndices ~= nil and #connectedAttributeIndices > 0 then
        entry.connectedAttributeIndices = connectedAttributeIndices
    end
    return true
end
function ConnectedAttributes:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)
    if part.connectedAttributeIndices ~= nil then
        local i = 1
        for i = i, #part.connectedAttributeIndices do
            local index = part.connectedAttributeIndices[i]
            if self.spec_connectedAttributes.attributes[index] ~= nil then
                ConnectedAttributes.updateAttribute(spec.attributes[index])
            end
        end
    end
end
function ConnectedAttributes:updateDebugValues(values)
    local spec = self.spec_connectedAttributes
    local i = 1
    for i = i, #spec.attributes do
        local attribute = spec.attributes[i]
        if i > 1 then
            table.insert(values, {
                ["name"] = "-",
                ["value"] = "-"
            })
        end
        local i = 1
        local valuesStr = #attribute.prerequisites
        for i = i, valuesStr do
            local valueStr = {
                ["name"] = string.format("prerequisite %d", i),
                ["value"] = string.format("%s", attribute.prerequisites[i]())
            }
            table.insert(values, valueStr)
        end
        local i = 1
        local valuesStr = #attribute.sources
        for i = i, valuesStr do
            local object = attribute.sources[i].object
            local valueStr = ""
            for _, value in pairs(object.data) do
                valueStr = string.format("%s %.2f", valueStr, MathUtil.round(value, 2))
            end
            table.insert(values, {
                ["name"] = string.format("source %d (%s)", i, object.NAME),
                ["value"] = valueStr
            })
        end
        local valuesStr = ""
        for object, valueStr in pairs(attribute.values) do
            valuesStr = string.format("%s (%s: %.2f)", valuesStr, object, MathUtil.round(valueStr, 2))
        end
        table.insert(values, {
            ["name"] = "current values",
            ["value"] = valuesStr
        })
        local source = 1
        local i = 1
        for source = source, #attribute.targets, i do
            local valueStr = attribute.targets[source].object
            local valueStr = ""
            for value, value in pairs(valueStr.data) do
                valueStr = string.format("%s %.2f", valueStr, MathUtil.round(value, 2))
            end
            table.insert(values, {
                ["name"] = string.format("target %d (%s)", source, valueStr.NAME),
                ["value"] = valueStr
            })
        end
    end
end
ConnectedAttributes.TYPES = {}
ConnectedAttributes.TYPES_BY_NAME = {}
ConnectedAttributes.TYPES_STRING = ""
function ConnectedAttributes.addType(class)
    ConnectedAttributes.TYPES_BY_NAME[class.NAME] = class
    if ConnectedAttributes.TYPES_STRING ~= "" then
        ConnectedAttributes.TYPES_STRING = ConnectedAttributes.TYPES_STRING .. ", "
    end
    ConnectedAttributes.TYPES_STRING = ConnectedAttributes.TYPES_STRING .. class.NAME
    table.insert(ConnectedAttributes.TYPES, class)
end
local LocalOffset = {}
local LocalOffset_mt = Class(LocalOffset)
LocalOffset.NAME = "LOCAL_OFFSET"
LocalOffset.NUM_VALUES = 3
function LocalOffset.registerSourceXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".localOffset#node", "Reference node to measure the offset to the defined source node")
end
function LocalOffset.registerTargetXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".localOffset#node", "Node to set to the offset position that is calculated from the defined target node")
end
function LocalOffset.new(_, node, xmlFile, key, components, i3dMappings)
    -- upvalues: (copy) LocalOffset_mt
    local self = {}
    setmetatable(self, LocalOffset_mt)
    self.parentNode = node
    self.node = xmlFile:getValue(key .. ".localOffset#node", nil, components, i3dMappings)
    if self.node == nil then
        Logging.xmlWarning(xmlFile, "Invalid shaderParameter \'%s\' for node \'%s\'", self.name, getName(node))
        return nil
    else
        self.data = { 0, 0, 0 }
        return self
    end
end
function LocalOffset:get()
    self.data[1], self.data[2], self.data[3] = localToLocal(self.node, self.parentNode, 0, 0, 0)
end
function LocalOffset:set()
    local x, y, z = localToLocal(self.parentNode, getParent(self.node), self.data[1], self.data[2], self.data[3])
    setTranslation(self.node, x, y, z)
end
ConnectedAttributes.addType(LocalOffset)
local ShaderParameter = {}
local ShaderParameter_mt = Class(ShaderParameter)
ShaderParameter.NAME = "SHADER_PARAMETER"
ShaderParameter.NUM_VALUES = 4
function ShaderParameter.registerSourceXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".shaderParameter#name", "Name of shader parameter of the source node that is used")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Name of shader parameter of the source node that is used")
end
function ShaderParameter.registerTargetXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".shaderParameter#name", "Name of shader parameter of the target node that is used")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Name of shader parameter of the target node that is used")
end
function ShaderParameter.new(_, node, xmlFile, key, _, _)
    -- upvalues: (copy) ShaderParameter_mt, (copy) ShaderParameter
    local self = {}
    setmetatable(self, ShaderParameter_mt)
    self.parentNode = node
    self.name = xmlFile:getValue(key .. ".shaderParameter#name") or xmlFile:getValue(key .. "#shaderParameterName")
    if self.name == nil or not getHasShaderParameter(node, self.name) then
        Logging.xmlWarning(xmlFile, "Invalid shaderParameter \'%s\' for node \'%s\'", self.name, getName(node))
        return nil
    end
    self.data = {
        0,
        0,
        0,
        0
    }
    local prevName = "prev" .. string.upper((string.sub(self.name, 1, 1))) .. string.sub(self.name, 2)
    if getHasShaderParameter(node, prevName) then
        self.prevName = prevName
        self.set = ShaderParameter.prev_set
    end
    self.numMaterials = getNumOfMaterials(self.parentNode)
    return self
end
function ShaderParameter:get()
    self.data[1], self.data[2], self.data[3], self.data[4] = getShaderParameter(self.parentNode, self.name)
end
function ShaderParameter:set()
    setShaderParameter(self.parentNode, self.name, self.data[1], self.data[2], self.data[3], self.data[4], false)
end
function ShaderParameter:prev_set()
    g_animationManager:setPrevShaderParameter(self.parentNode, self.name, self.data[1], self.data[2], self.data[3], self.data[4], false, self.prevName)
end
ConnectedAttributes.addType(ShaderParameter)
local ShaderParameterPrev = {}
local ShaderParameterPrev_mt = Class(ShaderParameterPrev)
ShaderParameterPrev.NAME = "SHADER_PARAMETER_PREV"
ShaderParameterPrev.NUM_VALUES = 8
function ShaderParameterPrev.registerSourceXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".shaderParameter#name", "Name of shader parameter of the source node that is used")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Name of shader parameter of the source node that is used")
end
function ShaderParameterPrev.registerTargetXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".shaderParameter#name", "Name of shader parameter of the target node that is used")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Name of shader parameter of the target node that is used")
end
function ShaderParameterPrev.new(_, node, xmlFile, key, _, _)
    -- upvalues: (copy) ShaderParameterPrev_mt
    local self = {}
    setmetatable(self, ShaderParameterPrev_mt)
    self.parentNode = node
    self.name = xmlFile:getValue(key .. ".shaderParameter#name") or xmlFile:getValue(key .. "#shaderParameterName")
    if self.name == nil or not getHasShaderParameter(node, self.name) then
        Logging.xmlWarning(xmlFile, "Invalid shaderParameter \'%s\' for node \'%s\'", self.name, getName(node))
        return nil
    end
    self.data = {
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    }
    local prevName = "prev" .. string.upper((string.sub(self.name, 1, 1))) .. string.sub(self.name, 2)
    if not getHasShaderParameter(node, prevName) then
        return nil
    end
    self.prevName = prevName
    return self
end
function ShaderParameterPrev:get()
    self.data[1], self.data[2], self.data[3], self.data[4] = getShaderParameter(self.parentNode, self.name)
    self.data[5], self.data[6], self.data[7], self.data[8] = getShaderParameter(self.parentNode, self.prevName)
end
function ShaderParameterPrev:set()
    setShaderParameter(self.parentNode, self.name, self.data[1], self.data[2], self.data[3], self.data[4], false)
    setShaderParameter(self.parentNode, self.prevName, self.data[5], self.data[6], self.data[7], self.data[8], false)
end
ConnectedAttributes.addType(ShaderParameterPrev)
local Translation = {}
local Translation_mt = Class(Translation)
Translation.NAME = "TRANSLATION"
Translation.NUM_VALUES = 3
function Translation.registerSourceXMLPaths(schema, basePath) end
function Translation.registerTargetXMLPaths(schema, basePath) end
function Translation.new(vehicle, node, _, _, _, _)
    -- upvalues: (copy) Translation_mt, (copy) Translation
    local self = {}
    setmetatable(self, Translation_mt)
    self.parentNode = node
    self.data = { 0, 0, 0 }
    if vehicle.setMovingToolDirty ~= nil then
        function self.set()
            -- upvalues: (ref) Translation, (copy) self, (copy) vehicle, (copy) node
            Translation.set(self)
            vehicle:setMovingToolDirty(node)
        end
    end
    return self
end
function Translation:get()
    self.data[1], self.data[2], self.data[3] = getTranslation(self.parentNode)
end
function Translation:set()
    setTranslation(self.parentNode, self.data[1], self.data[2], self.data[3])
end
ConnectedAttributes.addType(Translation)
local Rotation = {}
local Rotation_mt = Class(Rotation)
Rotation.NAME = "ROTATION"
Rotation.NUM_VALUES = 3
function Rotation.registerSourceXMLPaths(schema, basePath) end
function Rotation.registerTargetXMLPaths(schema, basePath) end
function Rotation.new(vehicle, node, _, _, _, _)
    -- upvalues: (copy) Rotation_mt, (copy) Rotation
    local self = {}
    setmetatable(self, Rotation_mt)
    self.parentNode = node
    self.data = { 0, 0, 0 }
    if vehicle.setMovingToolDirty ~= nil then
        function self.set()
            -- upvalues: (ref) Rotation, (copy) self, (copy) vehicle, (copy) node
            Rotation.set(self)
            vehicle:setMovingToolDirty(node)
        end
    end
    return self
end
function Rotation:get()
    local rx, ry, rz = getRotation(self.parentNode)
    self.data[1] = math.deg(rx)
    self.data[2] = math.deg(ry)
    self.data[3] = math.deg(rz)
end
function Rotation:set()
    setRotation(self.parentNode, math.rad(self.data[1]), math.rad(self.data[2]), (math.rad(self.data[3])))
end
ConnectedAttributes.addType(Rotation)
local JointLimitRot = {}
local JointLimitRot_mt = Class(JointLimitRot)
JointLimitRot.NAME = "JOINT_LIMIT_ROT"
JointLimitRot.NUM_VALUES = 6
function JointLimitRot.registerSourceXMLPaths(schema, basePath) end
function JointLimitRot.registerTargetXMLPaths(schema, basePath) end
function JointLimitRot.isAvailable(vehicle)
    return vehicle.isServer
end
function JointLimitRot.new(vehicle, node, xmlFile, key, _, _)
    -- upvalues: (copy) JointLimitRot_mt
    local self = {}
    local i = JointLimitRot_mt
    setmetatable(self, i)
    self.parentNode = node
    local i = 1
    for i = i, #vehicle.componentJoints do
        local componentJoint = vehicle.componentJoints[i]
        if componentJoint.jointNode == node then
            self.componentJoint = componentJoint
            if self.componentJoint ~= nil then
                self.data = {
                    0,
                    0,
                    0,
                    0,
                    0,
                    0
                }
                self.vehicle = vehicle
                return self
            end
        end
    end
    Logging.xmlWarning(xmlFile, "Unable to find component joint in \'%s\' for node \'%s\'", key, getName(node))
    return nil
end
function JointLimitRot:get()
    local componentJoint = self.componentJoint
    self.data[1] = math.deg(componentJoint.rotMinLimit[1])
    self.data[2] = math.deg(componentJoint.rotMinLimit[2])
    self.data[3] = math.deg(componentJoint.rotMinLimit[3])
    self.data[4] = math.deg(componentJoint.rotLimit[1])
    self.data[5] = math.deg(componentJoint.rotLimit[2])
    self.data[6] = math.deg(componentJoint.rotLimit[3])
end
function JointLimitRot:set()
    self.vehicle:setComponentJointRotLimit(self.componentJoint, 1, math.rad(self.data[1]), (math.rad(self.data[4])))
    self.vehicle:setComponentJointRotLimit(self.componentJoint, 2, math.rad(self.data[2]), (math.rad(self.data[5])))
    self.vehicle:setComponentJointRotLimit(self.componentJoint, 3, math.rad(self.data[3]), (math.rad(self.data[6])))
end
ConnectedAttributes.addType(JointLimitRot)
local JointLimitTrans = {}
local JointLimitTrans_mt = Class(JointLimitTrans)
JointLimitTrans.NAME = "JOINT_LIMIT_TRANS"
JointLimitTrans.NUM_VALUES = 6
function JointLimitTrans.registerSourceXMLPaths(schema, basePath) end
function JointLimitTrans.registerTargetXMLPaths(schema, basePath) end
function JointLimitTrans.isAvailable(vehicle)
    return vehicle.isServer
end
function JointLimitTrans.new(vehicle, node, xmlFile, key, _, _)
    -- upvalues: (copy) JointLimitTrans_mt
    local self = {}
    local i = JointLimitTrans_mt
    setmetatable(self, i)
    self.parentNode = node
    local i = 1
    for i = i, #vehicle.componentJoints do
        local componentJoint = vehicle.componentJoints[i]
        if componentJoint.jointNode == node then
            self.componentJoint = componentJoint
            if self.componentJoint ~= nil then
                self.data = {
                    0,
                    0,
                    0,
                    0,
                    0,
                    0
                }
                self.vehicle = vehicle
                return self
            end
        end
    end
    Logging.xmlWarning(xmlFile, "Unable to find component joint in \'%s\' for node \'%s\'", key, getName(node))
    return nil
end
function JointLimitTrans:get()
    local componentJoint = self.componentJoint
    self.data[1] = componentJoint.transMinLimit[1]
    self.data[2] = componentJoint.transMinLimit[2]
    self.data[3] = componentJoint.transMinLimit[3]
    self.data[4] = componentJoint.transLimit[1]
    self.data[5] = componentJoint.transLimit[2]
    self.data[6] = componentJoint.transLimit[3]
end
function JointLimitTrans:set()
    self.vehicle:setComponentJointTransLimit(self.componentJoint, 1, self.data[1], self.data[4])
    self.vehicle:setComponentJointTransLimit(self.componentJoint, 2, self.data[2], self.data[5])
    self.vehicle:setComponentJointTransLimit(self.componentJoint, 3, self.data[3], self.data[6])
end
ConnectedAttributes.addType(JointLimitTrans)
local AnimationTime = {}
local AnimationTime_mt = Class(AnimationTime)
AnimationTime.NAME = "ANIMATION_TIME"
AnimationTime.NUM_VALUES = 1
function AnimationTime.registerSourceXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".animation#name", "Name of animation from which the time is used")
end
function AnimationTime.registerTargetXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".animation#name", "Name of animation onto which the value is applied as time")
    schema:register(XMLValueType.STRING, basePath .. ".animation#minValue", "Min. reference value (when input value is at this point, animation time \'0\' is used)")
    schema:register(XMLValueType.STRING, basePath .. ".animation#maxValue", "Max. reference value (when input value is at this point, animation time \'1\' is used)")
end
function AnimationTime.new(vehicle, node, xmlFile, key, _, _)
    -- upvalues: (copy) AnimationTime_mt, (copy) AnimationTime
    local self = {}
    setmetatable(self, AnimationTime_mt)
    self.parentNode = node
    if vehicle.getAnimationExists == nil then
        Logging.xmlWarning(xmlFile, "Vehicle does not have animations for \'%s\'", key)
        return nil
    end
    self.name = xmlFile:getValue(key .. ".animation#name")
    if self.name == nil or not vehicle:getAnimationExists(self.name) then
        Logging.xmlWarning(xmlFile, "Invalid animation \'%s\' in \'%s\'", self.name, key)
        return nil
    end
    self.minValue = xmlFile:getValue(key .. ".animation#minValue")
    self.maxValue = xmlFile:getValue(key .. ".animation#maxValue")
    if self.minValue ~= nil ~= (self.maxValue ~= nil) then
        Logging.xmlWarning(xmlFile, "Invalid animation values for \'%s\' in \'%s\' (minValue and maxValue need to be defined, or non of them)", self.name, key)
        return nil
    end
    if self.minValue ~= nil and self.maxValue ~= nil then
        self.set = AnimationTime.range_set
    end
    self.data = { 0 }
    self.vehicle = vehicle
    return self
end
function AnimationTime:get()
    self.data[1] = self.vehicle:getAnimationTime(self.name)
end
function AnimationTime:set()
    self.vehicle:setAnimationTime(self.name, self.data[1], true)
end
function AnimationTime:range_set()
    self.vehicle:setAnimationTime(self.name, (self.data[1] - self.minValue) / (self.maxValue - self.minValue), true)
end
ConnectedAttributes.addType(AnimationTime)