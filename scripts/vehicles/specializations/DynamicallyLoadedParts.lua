DynamicallyLoadedParts = {}
function DynamicallyLoadedParts.prerequisitesPresent(specializations)
    return true
end
function DynamicallyLoadedParts.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("DynamicallyLoadedParts")
    schema:register(XMLValueType.STRING, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#filename", "Filename to i3d file")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#node", "Node in external i3d file", "0|0")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#linkNode", "Link node", "0>")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#position", "Position", "0 0 0")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#rotationNode", "Rotation node", "node")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#rotation", "Rotation node rotation")
    schema:register(XMLValueType.STRING, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#shaderParameterName", "Shader parameter name")
    schema:register(XMLValueType.VECTOR_4, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#shaderParameter", "Shader parameter to apply")
    schema:setXMLSpecializationType()
end
function DynamicallyLoadedParts.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onDynamicallyPartI3DLoaded", DynamicallyLoadedParts.onDynamicallyPartI3DLoaded)
end
function DynamicallyLoadedParts.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicallyLoadedParts)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicallyLoadedParts)
end
function DynamicallyLoadedParts:onLoad(_)
    local spec = self.spec_dynamicallyLoadedParts
    spec.sharedLoadRequestIds = {}
    spec.parts = {}
    self.xmlFile:iterate("vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart", function(_, partKey)
        -- upvalues: (copy) self, (copy) spec
        local filename = self.xmlFile:getValue(partKey .. "#filename")
        if filename == nil then
            Logging.xmlWarning(self.xmlFile, "Missing filename for dynamically loaded part \'%s\'", partKey)
        else
            local dynamicallyLoadedPart = {
                ["filename"] = Utils.getFilename(filename, self.baseDirectory)
            }
            local sharedLoadRequestId = self:loadSubSharedI3DFile(dynamicallyLoadedPart.filename, false, false, self.onDynamicallyPartI3DLoaded, self, {
                ["xmlFile"] = self.xmlFile,
                ["partKey"] = partKey,
                ["dynamicallyLoadedPart"] = dynamicallyLoadedPart
            })
            table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
        end
    end)
end
function DynamicallyLoadedParts:onDelete()
    local spec = self.spec_dynamicallyLoadedParts
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
        spec.sharedLoadRequestIds = nil
    end
end
function DynamicallyLoadedParts:onDynamicallyPartI3DLoaded(i3dNode, _, args)
    local xmlFile = args.xmlFile
    local partKey = args.partKey
    local dynamicallyLoadedPart = args.dynamicallyLoadedPart
    if i3dNode == 0 then
        Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to load i3d", partKey)
        return false
    end
    local node = xmlFile:getValue(partKey .. "#node", "0|0", i3dNode)
    if node == nil then
        Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find node in loaded i3d", partKey)
        delete(i3dNode)
        return false
    end
    local linkNode = xmlFile:getValue(partKey .. "#linkNode", "0>", self.components, self.i3dMappings)
    if linkNode == nil then
        Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find linkNode", partKey)
        delete(i3dNode)
        return false
    end
    local isReference, filename, runtimeLoaded = getReferenceInfo(linkNode)
    if not (isReference and runtimeLoaded) then
        local isReference, filename, runtimeLoaded = xmlFile:getValue(partKey .. "#position")
        if isReference == nil or (filename == nil or runtimeLoaded == nil) then
            setTranslation(node, 0, 0, 0)
        else
            setTranslation(node, isReference, filename, runtimeLoaded)
        end
        setRotation(node, 0, 0, 0)
        local xmlName = xmlFile:getValue(partKey .. "#rotationNode", node, i3dNode)
        local i3dName, rotY, rotZ = xmlFile:getValue(partKey .. "#rotation")
        if i3dName ~= nil and (rotY ~= nil and rotZ ~= nil) then
            setRotation(xmlName, i3dName, rotY, rotZ)
        end
        local shaderParameterName = xmlFile:getValue(partKey .. "#shaderParameterName")
        local sx, sy, sz, sw = xmlFile:getValue(partKey .. "#shaderParameter")
        if shaderParameterName ~= nil and (sx ~= nil and (sy ~= nil and (sz ~= nil and sw ~= nil))) then
            setShaderParameter(node, shaderParameterName, sx, sy, sz, sw, false)
        end
        link(linkNode, node)
        delete(i3dNode)
        table.insert(self.spec_dynamicallyLoadedParts.parts, dynamicallyLoadedPart)
        return true
    end
    local xmlName = Utils.getFilenameInfo(dynamicallyLoadedPart.filename, true)
    local i3dName = Utils.getFilenameInfo(filename, true)
    if xmlName ~= i3dName then
        Logging.xmlWarning(xmlFile, "DynamicallyLoadedPart \'%s\' loading different file from XML compared to i3D. (XML: %s vs i3D: %s)", getName(linkNode), xmlName, i3dName)
    end
    Logging.xmlWarning(xmlFile, "DynamicallyLoadedPart link node \'%s\' is a runtime loaded reference. Please load it either via XML or the i3D reference, but not both!", getName(linkNode))
    delete(i3dNode)
end