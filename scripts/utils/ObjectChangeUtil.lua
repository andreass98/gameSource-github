ObjectChangeUtil = {}
function ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, objects, rootNode, parent)
    for _, nodeKey in xmlFile:iterator(key .. ".objectChange") do
        local i3dMappings = nil
        if parent ~= nil then
            i3dMappings = parent.i3dMappings
        end
        local node = xmlFile:getValue(nodeKey .. "#node", nil, rootNode, i3dMappings)
        if node ~= nil then
            local object = {
                ["node"] = node
            }
            ObjectChangeUtil.loadValuesFromXML(xmlFile, nodeKey, node, object, parent, rootNode, i3dMappings)
            objects = objects or {}
            table.insert(objects, object)
        end
    end
    return objects
end
function ObjectChangeUtil.loadValueType(targetTable, xmlFile, key, name, getFunc, setFunc, interpolatable, ...)
    local active = xmlFile:getValue(key .. "#" .. name .. "Active", ...)
    local inactive = xmlFile:getValue(key .. "#" .. name .. "Inactive", ...)
    if active == nil and inactive == nil then
        return nil
    end
    local entry = {
        ["active"] = active ~= nil and type(active) ~= "table" and { active } or active,
        ["inactive"] = inactive ~= nil and type(inactive) ~= "table" and { inactive } or inactive,
        ["getFunc"] = getFunc,
        ["setFunc"] = setFunc,
        ["interpolatable"] = interpolatable,
        ["name"] = name
    }
    table.insert(targetTable, entry)
    return entry
end
function ObjectChangeUtil.loadValuesFromXML(xmlFile, key, node, object, parent, rootNode, i3dMappings)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionActive", key .. "#compoundChildActive or #rigidBodyTypeActive")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionInactive", key .. "#compoundChildInactive or #rigidBodyTypeInactive")
    object.parent = parent
    object.interpolation = xmlFile:getValue(key .. "#interpolation", false)
    object.interpolationTime = xmlFile:getValue(key .. "#interpolationTime", 1)
    object.values = {}
    local entry = ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "parentNode", nil, function(parentNode)
        -- upvalues: (copy) node
        local x, y, z = getWorldTranslation(node)
        local rx, ry, rz = getWorldRotation(node)
        link(parentNode, node)
        setWorldTranslation(node, x, y, z)
        setWorldRotation(node, rx, ry, rz)
    end, false, nil, rootNode, i3dMappings)
    if entry ~= nil then
        if entry.active == nil then
            entry.active = { getParent(object.node) }
        end
        if entry.inactive == nil then
            entry.inactive = { getParent(object.node) }
        end
    end
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "delete", nil, function(doDelete)
        -- upvalues: (copy) node
        if doDelete then
            local parent = getParent(node)
            local name = getName(node)
            local deletedName = string.format("%s_deletedByObjectChange", name)
            local index = getChildIndex(node)
            local emptyTG = createTransformGroup(deletedName)
            link(parent, emptyTG, index)
            delete(node)
        end
    end, false)
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "translation", function()
        -- upvalues: (copy) node
        return getTranslation(node)
    end, function(x, y, z)
        -- upvalues: (copy) node
        setTranslation(node, x, y, z)
    end, true, nil, true)
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "rotation", function()
        -- upvalues: (copy) node
        return getRotation(node)
    end, function(x, y, z)
        -- upvalues: (copy) node
        setRotation(node, x, y, z)
    end, true, nil, true)
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "scale", function()
        -- upvalues: (copy) node
        return getScale(node)
    end, function(x, y, z)
        -- upvalues: (copy) node
        setScale(node, x, y, z)
    end, true, nil, true)
    local shaderParameter = xmlFile:getValue(key .. "#shaderParameter")
    if shaderParameter ~= nil then
        if xmlFile:getValue(key .. "#shaderParameterSetRecursive", false) then
            if I3DUtil.getHasShaderParameterRec(node, shaderParameter) then
                ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "shaderParameter", function()
                    -- upvalues: (copy) node, (copy) shaderParameter
                    return I3DUtil.getShaderParameterRec(node, shaderParameter)
                end, function(x, y, z, w)
                    -- upvalues: (copy) node, (copy) shaderParameter
                    setShaderParameterRecursive(node, shaderParameter, x, y, z, w, false)
                end, true, nil, true)
            else
                Logging.xmlWarning(xmlFile, "Missing shader parameter \'%s\' on object \'%s\' or any of its children (recursive) in \'%s\'", shaderParameter, getName(node), key)
            end
        elseif getHasClassId(node, ClassIds.SHAPE) then
            if getHasShaderParameter(node, shaderParameter) then
                local sharedShaderParameter = xmlFile:getValue(key .. "#sharedShaderParameter", false)
                ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "shaderParameter", function()
                    -- upvalues: (copy) node, (copy) shaderParameter
                    return getShaderParameter(node, shaderParameter)
                end, function(x, y, z, w)
                    -- upvalues: (copy) node, (copy) shaderParameter, (copy) sharedShaderParameter
                    setShaderParameter(node, shaderParameter, x, y, z, w, sharedShaderParameter)
                end, true, nil, true)
            else
                Logging.xmlWarning(xmlFile, "Missing shader parameter \'%s\' on object \'%s\' in \'%s\'", shaderParameter, getName(node), key)
            end
        else
            Logging.xmlWarning(xmlFile, "Given node %q at %q is not a shape and cannot have a shaderParameter applied to it", getName(node), key)
        end
    end
    local recursive = xmlFile:getString(key .. "#centerOfMassActive")
    local sharedShaderParameter = xmlFile:getString(key .. "#centerOfMassInactive")
    if recursive ~= nil or sharedShaderParameter ~= nil then
        local rigidBodyTypeActiveStr = (recursive or ""):split(" ")
        local rigidBodyTypeActiveStr = (sharedShaderParameter or ""):split(" ")
        object.centerOfMassMask = { 1, 1, 1 }
        object.centerOfMassMaskActive = false
        local i = 1
        local rigidBodyTypeActiveStr = 3
        for i = i, rigidBodyTypeActiveStr do
            if rigidBodyTypeActiveStr ~= nil and rigidBodyTypeActiveStr[i] == "-" then
                object.centerOfMassMask[i] = 0
                object.centerOfMassMaskActive = true
            end
            if rigidBodyTypeActiveStr ~= nil and rigidBodyTypeActiveStr[i] == "-" then
                object.centerOfMassMask[i] = 0
                object.centerOfMassMaskActive = true
            end
        end
    end
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "centerOfMass", function()
        -- upvalues: (copy) node
        return getCenterOfMass(node)
    end, function(x, y, z)
        -- upvalues: (copy) object, (copy) node
        local cz, cy, cx
        if object.centerOfMassMaskActive == nil then
            cz = z
            cy = y
            cx = x
        else
            cx, cy, cz = getCenterOfMass(node)
            if object.centerOfMassMask[1] ~= 0 then
                cx = x
            end
            if object.centerOfMassMask[2] ~= 0 then
                cy = y
            end
            if object.centerOfMassMask[3] ~= 0 then
                cz = z
            end
        end
        setCenterOfMass(node, cx, cy, cz)
    end, true, nil, true)
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "mass", function()
        -- upvalues: (copy) node
        return getMass(node)
    end, function(value)
        -- upvalues: (copy) node, (copy) parent, (copy) object
        setMass(node, value / 1000)
        if parent ~= nil and parent.components ~= nil then
            for _, component in ipairs(parent.components) do
                if component.node == object.node then
                    component.defaultMass = value / 1000
                    parent:setMassDirty()
                end
            end
        end
    end, true)
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "visibility", nil, function(state)
        -- upvalues: (copy) node
        setVisibility(node, state)
    end, false)
    ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "compoundChild", nil, function(state)
        -- upvalues: (copy) node
        setIsCompoundChild(node, state)
    end, false)
    local rigidBodyTypeActiveStr = xmlFile:getValue(key .. "#rigidBodyTypeActive")
    if rigidBodyTypeActiveStr ~= nil then
        object.rigidBodyTypeActive = RigidBodyType[string.upper(rigidBodyTypeActiveStr)]
        local t = object.rigidBodyTypeActive
        if t ~= RigidBodyType.STATIC and (t ~= RigidBodyType.DYNAMIC and (t ~= RigidBodyType.KINEMATIC and t ~= RigidBodyType.NONE)) then
            Logging.xmlWarning(xmlFile, "Invalid rigidBodyTypeActive \'%s\' for object change node \'%s\'. Use \'Static\', \'Dynamic\', \'Kinematic\' or \'None\'!", rigidBodyTypeActiveStr, key)
            object.rigidBodyTypeActive = nil
        end
    end
    local t = xmlFile:getValue(key .. "#rigidBodyTypeInactive")
    if t ~= nil then
        object.rigidBodyTypeInactive = RigidBodyType[string.upper(t)]
        local i = object.rigidBodyTypeInactive
        if i ~= RigidBodyType.STATIC and (i ~= RigidBodyType.DYNAMIC and (i ~= RigidBodyType.KINEMATIC and i ~= RigidBodyType.NONE)) then
            Logging.xmlWarning(xmlFile, "Invalid rigidBodyTypeInactive \'%s\' for object change node \'%s\'. Use \'Static\', \'Dynamic\', \'Kinematic\' or \'None\'!", t, key)
            object.rigidBodyTypeInactive = nil
        end
    end
    if parent ~= nil and parent.loadObjectChangeValuesFromXML ~= nil then
        parent:loadObjectChangeValuesFromXML(xmlFile, key, node, object)
    end
end
function ObjectChangeUtil.setObjectChanges(objects, isActive, target, updateFunc, skipInterpolation)
    if objects ~= nil then
        for _, object in pairs(objects) do
            ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc, skipInterpolation)
        end
    end
end
function ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc, skipInterpolation)
    if isActive then
        local i = 1
        for i = i, #object.values do
            local value = object.values[i]
            if value.active ~= nil then
                if object.interpolation and (value.interpolatable and not skipInterpolation) then
                    local interpolator = ValueInterpolator.new(object.node .. value.name, value.getFunc, value.setFunc, value.active, object.interpolationTime)
                    if interpolator ~= nil then
                        interpolator:setUpdateFunc(updateFunc, target, object.node)
                        interpolator:setDeleteListenerObject(object.parent)
                    end
                else
                    if skipInterpolation then
                        ValueInterpolator.removeInterpolator(object.node .. value.name)
                    end
                    value.setFunc(unpack(value.active))
                end
            end
        end
        if object.rigidBodyTypeActive ~= nil then
            setRigidBodyType(object.node, object.rigidBodyTypeActive)
        end
    else
        local i = 1
        for i = i, #object.values do
            local value = object.values[i]
            if value.inactive ~= nil then
                if object.interpolation and (value.interpolatable and not skipInterpolation) then
                    local interpolator = ValueInterpolator.new(object.node .. value.name, value.getFunc, value.setFunc, value.inactive, object.interpolationTime)
                    if interpolator ~= nil then
                        interpolator:setUpdateFunc(updateFunc, target, object.node)
                        interpolator:setDeleteListenerObject(object.parent)
                    end
                else
                    if skipInterpolation then
                        ValueInterpolator.removeInterpolator(object.node .. value.name)
                    end
                    value.setFunc(unpack(value.inactive))
                end
            end
        end
        if object.rigidBodyTypeInactive ~= nil then
            setRigidBodyType(object.node, object.rigidBodyTypeInactive)
        end
    end
    if target ~= nil then
        if target.setObjectChangeValues ~= nil then
            target:setObjectChangeValues(object, isActive)
        end
        if updateFunc ~= nil then
            updateFunc(target, object.node)
        end
    end
end
function ObjectChangeUtil.updateObjectChanges(xmlFile, key, configIndex, rootNode, parent)
    local i = 0
    local activeI = configIndex - 1
    while true do
        local objectChangeKey = string.format(key .. "(%d)", i)
        if not xmlFile:hasProperty(objectChangeKey) then
            break
        end
        if i ~= activeI then
            local objects = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, objectChangeKey, nil, rootNode, parent)
            ObjectChangeUtil.setObjectChanges(objects, false, parent)
        end
        i = i + 1
    end
    if activeI < i then
        local objectChangeKey = string.format(key .. "(%d)", activeI)
        local objects = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, objectChangeKey, nil, rootNode, parent)
        ObjectChangeUtil.setObjectChanges(objects, true, parent)
    end
end
function ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("ObjectChange_single", basePath)
    ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
    schema:resetXMLSharedRegistration("ObjectChange_single", basePath)
end
function ObjectChangeUtil.registerObjectChangesXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("ObjectChange_multiple", basePath)
    ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath .. ".objectChanges")
    schema:resetXMLSharedRegistration("ObjectChange_multiple", basePath)
end
function ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
    schema:addDelayedRegistrationPath(basePath .. ".objectChange(?)", "ObjectChange")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#node", "Object change node")
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#interpolation", "Value will be interpolated", false)
    schema:register(XMLValueType.TIME, basePath .. ".objectChange(?)#interpolationTime", "Time for interpolation", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#deleteActive", string.format("%s if object change is active", "delete"))
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#deleteInactive", string.format("%s if object change is active", "delete"))
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#visibilityActive", string.format("%s if object change is active", "visibility"))
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#visibilityInactive", string.format("%s if object change is in active", "visibility"))
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".objectChange(?)#translationActive", string.format("%s if object change is active", "translation"))
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".objectChange(?)#translationInactive", string.format("%s if object change is in active", "translation"))
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".objectChange(?)#rotationActive", string.format("%s if object change is active", "rotation"))
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".objectChange(?)#rotationInactive", string.format("%s if object change is in active", "rotation"))
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".objectChange(?)#scaleActive", string.format("%s if object change is active", "scale"))
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".objectChange(?)#scaleInactive", string.format("%s if object change is in active", "scale"))
    schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#shaderParameter", "Shader parameter name")
    schema:register(XMLValueType.VECTOR_4, basePath .. ".objectChange(?)#shaderParameterActive", string.format("%s if object change is active", "shaderParameter"))
    schema:register(XMLValueType.VECTOR_4, basePath .. ".objectChange(?)#shaderParameterInactive", string.format("%s if object change is in active", "shaderParameter"))
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#sharedShaderParameter", "Shader parameter is applied on all objects with the same material", false)
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#shaderParameterSetRecursive", "Shader parameter is applied to all child nodes recursively", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#massActive", string.format("%s if object change is active", "mass"))
    schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#massInactive", string.format("%s if object change is in active", "mass"))
    schema:register(XMLValueType.VECTOR_3, basePath .. ".objectChange(?)#centerOfMassActive", string.format("%s if object change is active", "center of mass"))
    schema:register(XMLValueType.VECTOR_3, basePath .. ".objectChange(?)#centerOfMassInactive", string.format("%s if object change is in active", "center of mass"))
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#compoundChildActive", string.format("%s if object change is active", "compound child state"))
    schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#compoundChildInactive", string.format("%s if object change is in active", "compound child state"))
    schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#rigidBodyTypeActive", string.format("%s if object change is active", "rigid body type"))
    schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#rigidBodyTypeInactive", string.format("%s if object change is in active", "rigid body type"))
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#parentNodeActive", string.format("%s if object change is active", "parent node"))
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#parentNodeInactive", string.format("%s if object change is in active", "parent node"))
end
function ObjectChangeUtil.addAdditionalObjectChangeXMLPaths(schema, func)
    schema:addDelayedRegistrationFunc("ObjectChange", func)
end