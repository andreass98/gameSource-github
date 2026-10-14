ConnectionHoseType = nil
ConnectionHoseManager = {}
ConnectionHoseManager.DEFAULT_HOSES_FILENAME = "data/shared/connectionHoses/connectionHoses.xml"
ConnectionHoseManager.xmlSchema = nil
local ConnectionHoseManager_mt = Class(ConnectionHoseManager, AbstractManager)
function ConnectionHoseManager.new(customMt)
    -- upvalues: (copy) ConnectionHoseManager_mt
    local self = AbstractManager.new(customMt or ConnectionHoseManager_mt)
    self:initDataStructures()
    ConnectionHoseManager.xmlSchema = XMLSchema.new("connectionHoses")
    ConnectionHoseManager:registerXMLPaths(ConnectionHoseManager.xmlSchema)
    return self
end
function ConnectionHoseManager:initDataStructures()
    self.xmlFiles = {}
    self.typeByName = {}
    ConnectionHoseType = self.typeByName
    self.basicHoses = {}
    self.sockets = {}
    self.sharedLoadRequestIds = {}
    self.modConnectionHosesToLoad = {}
end
function ConnectionHoseManager:loadMapData(_, _, baseDirectory)
    ConnectionHoseManager:superClass().loadMapData(self)
    self.baseDirectory = baseDirectory
    self:loadConnectionHosesFromXML(ConnectionHoseManager.DEFAULT_HOSES_FILENAME, nil, self.baseDirectory)
    local i = #self.modConnectionHosesToLoad
    for i = i, 1, -1 do
        local modConnectionHoseToLoad = self.modConnectionHosesToLoad[i]
        self:loadConnectionHosesFromXML(modConnectionHoseToLoad.xmlFilename, modConnectionHoseToLoad.customEnvironment, modConnectionHoseToLoad.baseDirectory)
        self.modConnectionHosesToLoad[i] = nil
    end
end
function ConnectionHoseManager:unloadMapData()
    for _, entry in ipairs(self.basicHoses) do
        delete(entry.node)
    end
    for _, entry in pairs(self.typeByName) do
        for _, adapter in pairs(entry.adapters) do
            delete(adapter.node)
            delete(adapter.detachedNode)
        end
        for _, adapter in pairs(entry.hoses) do
            delete(adapter.materialNode)
        end
    end
    for _, entry in pairs(self.sockets) do
        delete(entry.node)
    end
    local i = 1
    for i = i, #self.sharedLoadRequestIds do
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestIds[i])
    end
    for _, entry in pairs(self.xmlFiles) do
        self.xmlFiles[_] = nil
        _:delete()
    end
    ConnectionHoseManager:superClass().unloadMapData(self)
end
function ConnectionHoseManager:addModConnectionHoses(xmlFilename, customEnvironment, baseDirectory)
    table.insert(self.modConnectionHosesToLoad, {
        ["xmlFilename"] = xmlFilename,
        ["customEnvironment"] = customEnvironment,
        ["baseDirectory"] = baseDirectory
    })
end
function ConnectionHoseManager:loadConnectionHosesFromXML(xmlFilename, customEnvironment, baseDirectory)
    Logging.info("Loading ConnectionHoses from \'%s\'", xmlFilename)
    local xmlFile = XMLFile.load("TempHoses", xmlFilename, ConnectionHoseManager.xmlSchema)
    if xmlFile ~= nil then
        self.xmlFiles[xmlFile] = true
        xmlFile.references = 1
        local i = 0
        while true do
            local hoseKey = string.format("connectionHoses.basicHoses.basicHose(%d)", i)
            if not xmlFile:hasProperty(hoseKey) then
                break
            end
            local filename = xmlFile:getValue(hoseKey .. "#filename")
            if filename ~= nil then
                xmlFile.references = xmlFile.references + 1
                local arguments = Utils.getFilename(filename, baseDirectory)
                local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.basicHoseI3DFileLoaded, self, {
                    ["xmlFile"] = xmlFile,
                    ["hoseKey"] = hoseKey
                })
                table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
            end
            i = i + 1
        end
        local i = 0
        while true do
            local hoseKey = string.format("connectionHoses.connectionHoseTypes.connectionHoseType(%d)", i)
            if not xmlFile:hasProperty(hoseKey) then
                break
            end
            local filename = xmlFile:getValue(hoseKey .. "#name")
            if filename ~= nil then
                local arguments
                if self.typeByName[string.upper(filename)] == nil then
                    if customEnvironment ~= nil then
                    end
                    self.typeByName[string.upper(filename)] = {
                        ["name"] = filename,
                        ["adapters"] = {},
                        ["hoses"] = {}
                    }
                else
                    arguments = self.typeByName[string.upper(filename)]
                end
                local sharedLoadRequestId = 0
                while true do
                    local adapterKey = string.format("%s.adapter(%d)", hoseKey, sharedLoadRequestId)
                    if not xmlFile:hasProperty(adapterKey) then
                        break
                    end
                    local adapterName = xmlFile:getValue(adapterKey .. "#name", "DEFAULT")
                    if customEnvironment ~= nil then
                    end
                    local filename = xmlFile:getValue(adapterKey .. "#filename")
                    if filename ~= nil then
                        xmlFile.references = xmlFile.references + 1
                        local arguments = Utils.getFilename(filename, baseDirectory)
                        local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.adapterI3DFileLoaded, self, {
                            ["hoseType"] = arguments,
                            ["adapterName"] = adapterName,
                            ["xmlFile"] = xmlFile,
                            ["adapterKey"] = adapterKey
                        })
                        table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
                    end
                    sharedLoadRequestId = sharedLoadRequestId + 1
                end
                local sharedLoadRequestId = 0
                while true do
                    local adapterKey = string.format("%s.material(%d)", hoseKey, sharedLoadRequestId)
                    if not xmlFile:hasProperty(adapterKey) then
                        break
                    end
                    local adapterName = xmlFile:getValue(adapterKey .. "#name", "DEFAULT")
                    if customEnvironment ~= nil then
                    end
                    local filename = xmlFile:getValue(adapterKey .. "#filename")
                    if filename ~= nil then
                        xmlFile.references = xmlFile.references + 1
                        local arguments = Utils.getFilename(filename, baseDirectory)
                        local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.materialI3DFileLoaded, self, {
                            ["hoseType"] = arguments,
                            ["hoseName"] = adapterName,
                            ["xmlFile"] = xmlFile,
                            ["hoseKey"] = adapterKey
                        })
                        table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
                    end
                    sharedLoadRequestId = sharedLoadRequestId + 1
                end
            end
            i = i + 1
        end
        local i = 0
        while true do
            local hoseKey = string.format("connectionHoses.sockets.socket(%d)", i)
            if not xmlFile:hasProperty(hoseKey) then
                break
            end
            local filename = xmlFile:getValue(hoseKey .. "#name")
            if customEnvironment ~= nil then
            end
            local arguments = xmlFile:getValue(hoseKey .. "#filename")
            if filename ~= nil and arguments ~= nil then
                xmlFile.references = xmlFile.references + 1
                local sharedLoadRequestId = Utils.getFilename(arguments, baseDirectory)
                local adapterKey = g_i3DManager:loadSharedI3DFileAsync(sharedLoadRequestId, false, false, self.socketI3DFileLoaded, self, {
                    ["name"] = filename,
                    ["xmlFile"] = xmlFile,
                    ["socketKey"] = hoseKey
                })
                table.insert(self.sharedLoadRequestIds, adapterKey)
            end
            i = i + 1
        end
        xmlFile.references = xmlFile.references - 1
        if xmlFile.references == 0 then
            self.xmlFiles[xmlFile] = nil
            xmlFile:delete()
        end
    end
end
function ConnectionHoseManager:basicHoseI3DFileLoaded(i3dNode, _, args)
    local xmlFile = args.xmlFile
    if i3dNode ~= nil and i3dNode ~= 0 then
        local node = xmlFile:getValue(args.hoseKey .. "#node", nil, i3dNode)
        if node ~= nil then
            unlink(node)
            local entry = {
                ["node"] = node,
                ["startStraightening"] = xmlFile:getValue(hoseKey .. "#startStraightening", 2),
                ["endStraightening"] = xmlFile:getValue(hoseKey .. "#endStraightening", 2),
                ["minCenterPointAngle"] = xmlFile:getValue(hoseKey .. "#minCenterPointAngle", 90)
            }
            local length = xmlFile:getValue(hoseKey .. "#length")
            if length == nil then
                printWarning(string.format("Warning: Missing length attribute in \'%s\'", hoseKey))
            end
            local realLength = xmlFile:getValue(hoseKey .. "#realLength")
            if realLength == nil then
                printWarning(string.format("Warning: Missing realLength attribute in \'%s\'", hoseKey))
            end
            local diameter = xmlFile:getValue(hoseKey .. "#diameter")
            if diameter == nil then
                printWarning(string.format("Warning: Missing diameter attribute in \'%s\'", hoseKey))
            end
            if length ~= nil and (realLength ~= nil and diameter ~= nil) then
                entry.length = length
                entry.realLength = realLength
                entry.diameter = diameter
                table.insert(self.basicHoses, entry)
            end
        end
        delete(i3dNode)
    end
    xmlFile.references = xmlFile.references - 1
    if xmlFile.references == 0 then
        self.xmlFiles[xmlFile] = nil
        xmlFile:delete()
    end
end
function ConnectionHoseManager:adapterI3DFileLoaded(i3dNode, _, args)
    local xmlFile = args.xmlFile
    if i3dNode ~= nil and i3dNode ~= 0 then
        local node = xmlFile:getValue(args.adapterKey .. "#node", nil, i3dNode)
        local hoseReferenceNode = getChildAt(node, 0)
        unlink(node)
        local detachedNode = xmlFile:getValue(adapterKey .. "#detachedNode", nil, i3dNode)
        if detachedNode ~= nil then
            unlink(detachedNode)
        end
        if hoseReferenceNode == 0 then
            printWarning(string.format("Warning: Missing hose reference node as child from adapter \'%s\' in connection type \'%s\'", args.adapterName, args.hoseType.name))
        else
            hoseType.adapters[string.upper(adapterName)] = {
                ["node"] = node,
                ["detachedNode"] = detachedNode,
                ["hoseReferenceNode"] = hoseReferenceNode
            }
        end
        delete(i3dNode)
    end
    xmlFile.references = xmlFile.references - 1
    if xmlFile.references == 0 then
        self.xmlFiles[xmlFile] = nil
        xmlFile:delete()
    end
end
function ConnectionHoseManager:materialI3DFileLoaded(i3dNode, _, args)
    local xmlFile = args.xmlFile
    if i3dNode ~= nil and i3dNode ~= 0 then
        local materialNode = xmlFile:getValue(args.hoseKey .. "#materialNode", nil, i3dNode)
        unlink(materialNode)
        if materialNode ~= nil then
            local entry = {
                ["materialNode"] = materialNode,
                ["uvMinMax"] = xmlFile:getValue(hoseKey .. "#uvMinMax", nil, true),
                ["uvLengthScale"] = xmlFile:getValue(hoseKey .. "#uvLengthScale", 1),
                ["uvRandomOffset"] = xmlFile:getValue(hoseKey .. "#uvRandomOffset", "0 0", true),
                ["materialTemplate"] = xmlFile:getValue(hoseKey .. "#materialTemplateName")
            }
            args.hoseType.hoses[string.upper(args.hoseName)] = entry
        end
        delete(i3dNode)
    end
    xmlFile.references = xmlFile.references - 1
    if xmlFile.references == 0 then
        self.xmlFiles[xmlFile] = nil
        xmlFile:delete()
    end
end
function ConnectionHoseManager:socketI3DFileLoaded(i3dNode, _, args)
    local xmlFile = args.xmlFile
    if i3dNode ~= nil and i3dNode ~= 0 then
        local node = xmlFile:getValue(args.socketKey .. "#node", nil, i3dNode)
        if node ~= nil then
            unlink(node)
            local entry = {
                ["node"] = node,
                ["referenceNode"] = xmlFile:getValue(socketKey .. "#referenceNode"),
                ["caps"] = {}
            }
            local j = 0
            while true do
                local capKey = string.format(socketKey .. ".cap(%d)", j)
                if not xmlFile:hasProperty(capKey) then
                    break
                end
                local cap = {
                    ["node"] = xmlFile:getValue(capKey .. "#node")
                }
                if cap.node ~= nil then
                    cap.openedRotation = xmlFile:getValue(capKey .. "#openedRotation", nil, true)
                    cap.closedRotation = xmlFile:getValue(capKey .. "#closedRotation", nil, true)
                    cap.openedVisibility = xmlFile:getValue(capKey .. "#openedVisibility", true)
                    cap.closedVisibility = xmlFile:getValue(capKey .. "#closedVisibility", true)
                    table.insert(entry.caps, cap)
                end
                j = j + 1
            end
            if self.sockets[string.upper(args.name)] == nil then
                self.sockets[string.upper(name)] = entry
            else
                Logging.xmlError(xmlFile, "Socket \'%s\' already exists", name)
            end
        end
        delete(i3dNode)
    end
    xmlFile.references = xmlFile.references - 1
    if xmlFile.references == 0 then
        self.xmlFiles[xmlFile] = nil
        xmlFile:delete()
    end
end
function ConnectionHoseManager:getHoseTypeByName(typeName, customEnvironment)
    if typeName == nil then
        return nil
    end
    if customEnvironment ~= nil then
        local customTypeName = string.upper(customEnvironment .. "." .. typeName)
        if self.typeByName[customTypeName] ~= nil then
            return self.typeByName[customTypeName]
        end
    end
    return self.typeByName[string.upper(typeName)]
end
function ConnectionHoseManager.getHoseAdapterByName(_, hoseType, adapterName, customEnvironment)
    if hoseType == nil or adapterName == nil then
        return nil
    end
    if customEnvironment ~= nil then
        local customTypeName = string.upper(customEnvironment .. "." .. adapterName)
        if hoseType.adapters[customTypeName] ~= nil then
            return hoseType.adapters[customTypeName]
        end
    end
    return hoseType.adapters[string.upper(adapterName)]
end
function ConnectionHoseManager.getHoseMaterialByName(_, hoseType, materialName, customEnvironment)
    if hoseType == nil or materialName == nil then
        return nil
    end
    if customEnvironment ~= nil then
        local customTypeName = string.upper(customEnvironment .. "." .. materialName)
        if hoseType.hoses[customTypeName] ~= nil then
            return hoseType.hoses[customTypeName]
        end
    end
    return hoseType.hoses[string.upper(materialName)]
end
function ConnectionHoseManager:getSocketByName(socketName, customEnvironment)
    if socketName == nil then
        return nil
    end
    if customEnvironment ~= nil then
        local customTypeName = string.upper(customEnvironment .. "." .. socketName)
        if self.sockets[customTypeName] ~= nil then
            return self.sockets[customTypeName]
        end
    end
    return self.sockets[string.upper(socketName)]
end
function ConnectionHoseManager:getClonedAdapterNode(typeName, adapterName, customEnvironment, detached)
    local hoseType = self:getHoseTypeByName(typeName, customEnvironment)
    if hoseType ~= nil then
        local adapter = self:getHoseAdapterByName(hoseType, adapterName, customEnvironment)
        if adapter ~= nil then
            if not detached then
                local adapterNodeClone = clone(adapter.node, true)
                setTranslation(adapterNodeClone, 0, 0, 0)
                setRotation(adapterNodeClone, 0, 0, 0)
                return adapterNodeClone, getChildAt(adapterNodeClone, 0)
            end
            if adapter.detachedNode ~= nil then
                local adapterNodeClone = clone(adapter.detachedNode, true)
                setTranslation(adapterNodeClone, 0, 0, 0)
                setRotation(adapterNodeClone, 0, 0, 0)
                return adapterNodeClone
            end
        end
    end
    return nil
end
function ConnectionHoseManager:getClonedHoseNode(typeName, hoseName, length, diameter, vehicleMaterial, customEnvironment)
    local hoseType = self:getHoseTypeByName(typeName, customEnvironment)
    if hoseType ~= nil then
        local material = self:getHoseMaterialByName(hoseType, hoseName, customEnvironment)
        if material ~= nil then
            local hoseNodeClone, realLength, startStraightening, endStraightening, minCenterPointAngle, closestDiameter = self:getClonedBasicHose(length, diameter)
            if hoseNodeClone ~= nil then
                local mat = getMaterial(material.materialNode, 0)
                setMaterial(hoseNodeClone, mat, 0)
                if material.materialTemplate ~= nil then
                    material.materialTemplate:apply(hoseNodeClone)
                end
                if vehicleMaterial ~= nil then
                    local newMat = setMaterialDiffuseMapFromFile(mat, "data/shared/detailLibrary/metallic/clear_diffuse.dds", true, true, false)
                    setMaterial(hoseNodeClone, newMat, 0)
                    vehicleMaterial:apply(hoseNodeClone)
                end
                setShaderParameter(hoseNodeClone, "lengthAndDiameter", realLength, diameter / closestDiameter, nil, nil, false)
                if material.uvMinMax ~= nil then
                    setShaderParameter(hoseNodeClone, "uvScale", length / realLength * material.uvLengthScale, material.uvMinMax[2] - material.uvMinMax[1], nil, nil, false)
                    local xOffset = material.uvRandomOffset[1]
                    local yOffset = material.uvRandomOffset[2]
                    if xOffset ~= 0 then
                        xOffset = math.random() * xOffset
                    end
                    if yOffset ~= 0 then
                        yOffset = math.random() * yOffset
                    end
                    setShaderParameter(hoseNodeClone, "offsetUV", xOffset, material.uvMinMax[1] + yOffset, nil, nil, false)
                end
                return hoseNodeClone, startStraightening, endStraightening, minCenterPointAngle
            end
        end
    end
    return nil, nil, nil, nil
end
function ConnectionHoseManager:getClonedBasicHose(length, diameter)
    local minDiameterDiff = math.huge
    local closestDiameter = math.huge
    for _, hose in pairs(self.basicHoses) do
        local diff = hose.diameter - diameter
        local diff = math.abs(diff)
        if diff < minDiameterDiff then
            closestDiameter = hose.diameter
            minDiameterDiff = diff
        end
    end
    local foundHoses = {}
    for hose, diff in pairs(self.basicHoses) do
        if math.abs(diff.diameter - closestDiameter) <= 0.0001 then
            table.insert(foundHoses, diff)
        end
    end
    local minLengthDiff = math.huge
    local foundHose = nil
    for diff, hose in pairs(foundHoses) do
        local diff = math.abs(hose.length - length)
        if diff < minLengthDiff then
            foundHose = hose
            minLengthDiff = diff
        end
    end
    if foundHose == nil then
        return nil
    else
        return clone(foundHose.node, true), foundHose.realLength, foundHose.startStraightening, foundHose.endStraightening, foundHose.minCenterPointAngle, closestDiameter
    end
end
function ConnectionHoseManager:linkSocketToNode(socketName, node, customEnvironment, socketMaterial)
    local socket = self:getSocketByName(socketName, customEnvironment)
    if socket == nil or node == nil then
        return nil
    end
    local linkedSocket = {
        ["node"] = clone(socket.node, true)
    }
    setTranslation(linkedSocket.node, 0, 0, 0)
    setRotation(linkedSocket.node, 0, 0, 0)
    linkedSocket.referenceNode = I3DUtil.indexToObject(linkedSocket.node, socket.referenceNode)
    linkedSocket.caps = {}
    for _, cap in ipairs(socket.caps) do
        local clonedCap = {}
        for i, v in pairs(cap) do
            clonedCap[i] = v
        end
        clonedCap.node = I3DUtil.indexToObject(linkedSocket.node, clonedCap.node)
        table.insert(linkedSocket.caps, clonedCap)
    end
    if socketMaterial ~= nil then
        socketMaterial:apply(linkedSocket.node, "connector_color_mat")
    end
    link(node, linkedSocket.node)
    self:closeSocket(linkedSocket)
    return linkedSocket
end
function ConnectionHoseManager.getSocketTarget(_, socket, defaultTarget)
    if socket == nil or socket.referenceNode == nil then
        return defaultTarget
    else
        return socket.referenceNode
    end
end
function ConnectionHoseManager.openSocket(_, socket)
    if socket ~= nil and #socket.caps > 0 then
        for _, cap in ipairs(socket.caps) do
            if cap.openedRotation ~= nil then
                setRotation(cap.node, unpack(cap.openedRotation))
            end
            setVisibility(cap.node, cap.openedVisibility)
        end
    end
end
function ConnectionHoseManager.closeSocket(_, socket)
    if socket ~= nil and #socket.caps > 0 then
        for _, cap in ipairs(socket.caps) do
            if cap.openedRotation ~= nil then
                setRotation(cap.node, unpack(cap.closedRotation))
            end
            setVisibility(cap.node, cap.closedVisibility)
        end
    end
end
function ConnectionHoseManager.registerXMLPaths(_, schema)
    schema:register(XMLValueType.STRING, "connectionHoses.basicHoses.basicHose(?)#filename", "I3d filename")
    schema:register(XMLValueType.NODE_INDEX, "connectionHoses.basicHoses.basicHose(?)#node", "Path to hose node")
    schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#startStraightening", "Straightening factor on start side", 2)
    schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#endStraightening", "Straightening factor on end side", 2)
    schema:register(XMLValueType.ANGLE, "connectionHoses.basicHoses.basicHose(?)#minCenterPointAngle", "Min. bending angle at the center of the hose", 90)
    schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#length", "Reference length of hose")
    schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#realLength", "Real length of hose in i3d")
    schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#diameter", "Diameter of hose")
    schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?)#name", "Name of type")
    schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#name", "Name of adapter")
    schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#filename", "Path to i3d file")
    schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#node", "Adapter node in i3d file")
    schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#detachedNode", "Detached adapter node in i3d file")
    schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#name", "Name of material")
    schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#filename", "Path to i3d file")
    schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#materialNode", "Material node in i3d file")
    schema:register(XMLValueType.VECTOR_2, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvMinMax", "Min. and max. range of uv\'s in Y")
    schema:register(XMLValueType.FLOAT, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvLengthScale", "Scale factor of the UV in X axis", 1)
    schema:register(XMLValueType.VECTOR_2, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvRandomOffset", "Random offset range on x and y axis", "0 0")
    schema:register(XMLValueType.VEHICLE_MATERIAL, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#materialTemplateName", "Material template to be applied by default")
    schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#name", "Socket name")
    schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#filename", "Path to i3d file")
    schema:register(XMLValueType.NODE_INDEX, "connectionHoses.sockets.socket(?)#node", "Socket node in i3d")
    schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#referenceNode", "Index of reference node inside socket")
    schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?).cap(?)#node", "Index of cap node inside socket")
    schema:register(XMLValueType.VECTOR_ROT, "connectionHoses.sockets.socket(?).cap(?)#openedRotation", "Opened rotation")
    schema:register(XMLValueType.VECTOR_ROT, "connectionHoses.sockets.socket(?).cap(?)#closedRotation", "Closed rotation")
    schema:register(XMLValueType.BOOL, "connectionHoses.sockets.socket(?).cap(?)#openedVisibility", "Opened visibility", true)
    schema:register(XMLValueType.BOOL, "connectionHoses.sockets.socket(?).cap(?)#closedVisibility", "Closed visibility", true)
end
g_connectionHoseManager = ConnectionHoseManager.new()