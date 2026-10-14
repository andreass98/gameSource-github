ToolConnectionHoseMount = {}
local ToolConnectionHoseMount_mt = Class(ToolConnectionHoseMount)
function ToolConnectionHoseMount.new(vehicle, customMt)
    -- upvalues: (copy) ToolConnectionHoseMount_mt
    local self = setmetatable({}, customMt or ToolConnectionHoseMount_mt)
    self.vehicle = vehicle
    self.components = {}
    self.i3dMappings = {}
    return self
end
function ToolConnectionHoseMount:delete()
    if self.xmlFile ~= nil then
        self.xmlFile:delete()
        self.xmlFile = nil
    end
    if self.node ~= nil then
        delete(self.node)
        self.node = nil
    end
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
end
function ToolConnectionHoseMount:setCallback(callback, callbackTarget)
    self.callback = callback
    self.callbackTarget = callbackTarget
end
function ToolConnectionHoseMount:onFinished(success)
    if self.callback ~= nil then
        if self.callbackTarget ~= nil then
            self.callback(self.callbackTarget, success)
            return
        end
        self.callback(success)
    end
end
function ToolConnectionHoseMount:setReferenceTargets(startTarget, endTarget)
    self.startTarget = startTarget
    self.endTarget = endTarget
    self.parentToolConnectionHose = self.vehicle.spec_connectionHoses.targetNodeToToolConnection[startTarget.index]
end
function ToolConnectionHoseMount:setLinkNode(linkNode, x, y, z, rx, ry, rz)
    self.linkNode = linkNode
    self.translation = { x or 0, y or 0, z or 0 }
    self.rotation = { rx or 0, ry or 0, rz or 0 }
end
function ToolConnectionHoseMount:loadFromXML(xmlFilename, baseDirectory)
    if self.startTarget == nil or self.endTarget == nil then
        Logging.warning("Missing start or end target for tool connection hose mount!")
        self:onFinished(false)
        return false
    end
    if self.linkNode == nil then
        Logging.warning("Missing link node for tool connection hose mount!")
        self:onFinished(false)
        return false
    end
    self.xmlFile = XMLFile.loadIfExists("toolConnectionHoseMount", xmlFilename, ToolConnectionHoseMount.xmlSchema)
    if self.xmlFile == nil then
        Logging.warning("Failed to load tool connection hose mount XML file: %s", xmlFilename)
        self:onFinished(false)
        return false
    end
    local filename = self.xmlFile:getValue("toolConnectionHoseMount.filename")
    if filename ~= nil then
        self.filename = Utils.getFilename(filename, baseDirectory)
        if self.vehicle == nil or self.vehicle.loadSubSharedI3DFile == nil then
            self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.onI3DLoaded, self, nil)
        else
            self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onI3DLoaded, self, nil)
        end
        return true
    end
    Logging.xmlWarning(self.xmlFile, "Missing toolConnectionHoseMount i3d filename!")
    self.xmlFile:delete()
    self.xmlFile = nil
    self:onFinished(false)
    return false
end
function ToolConnectionHoseMount:onI3DLoaded(i3dNode, _, _)
    if i3dNode ~= 0 then
        I3DUtil.loadI3DComponents(i3dNode, self.components)
        I3DUtil.loadI3DMapping(self.xmlFile, "toolConnectionHoseMount", self.components, self.i3dMappings)
        self.node = self.xmlFile:getValue("toolConnectionHoseMount.rootNode#node", "0", self.components, self.i3dMappings)
        if self.node ~= nil then
            self.length = self.xmlFile:getValue("toolConnectionHoseMount.rootNode#length", 3)
            self.targetNodes = {}
            self.xmlFile:iterate("toolConnectionHoseMount.target", function(_, baseKey)
                -- upvalues: (copy) self
                local target = {
                    ["backNode"] = self.xmlFile:getValue(baseKey .. "#backNode", nil, self.components, self.i3dMappings),
                    ["frontNode"] = self.xmlFile:getValue(baseKey .. "#frontNode", nil, self.components, self.i3dMappings),
                    ["mountingNode"] = self.xmlFile:getValue(baseKey .. "#mountingNode", nil, self.components, self.i3dMappings)
                }
                if target.backNode == nil or target.frontNode == nil then
                    Logging.xmlWarning(self.xmlFile, "Missing back or front node for tool connection hose mount target at \'%s\'!", baseKey)
                    return
                else
                    target.typeName = self.xmlFile:getValue(baseKey .. "#typeName")
                    if target.typeName == nil then
                        Logging.xmlWarning(self.xmlFile, "Missing type name for tool connection hose mount target at \'%s\'!", baseKey)
                    else
                        target.createHose = self.xmlFile:getValue(baseKey .. "#createHose", true)
                        target.moveNodes = self.xmlFile:getValue(baseKey .. "#moveNodes", true)
                        target.hoseOffset = self.xmlFile:getValue(baseKey .. "#hoseOffset", 0)
                        table.insert(self.targetNodes, target)
                    end
                end
            end)
            self.additionalHoses = {}
            self.xmlFile:iterate("toolConnectionHoseMount.hose", function(_, baseKey)
                -- upvalues: (copy) self
                local additionalHose = {
                    ["startNode"] = self.xmlFile:getValue(baseKey .. "#startNode", nil, self.components, self.i3dMappings),
                    ["endNode"] = self.xmlFile:getValue(baseKey .. "#endNode", nil, self.components, self.i3dMappings)
                }
                if additionalHose.startNode == nil or additionalHose.endNode == nil then
                    Logging.xmlWarning(self.xmlFile, "Missing start or end node for tool connection hose mount hose at \'%s\'!", baseKey)
                else
                    table.insert(self.additionalHoses, additionalHose)
                end
            end)
            self.adjustNodes = {}
            self.xmlFile:iterate("toolConnectionHoseMount.adjustNodes", function(_, baseKey)
                -- upvalues: (copy) self
                local adjustNode = {
                    ["node"] = self.xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings)
                }
                if adjustNode.node ~= nil then
                    adjustNode.startTranslation = { getTranslation(adjustNode.node) }
                    table.insert(self.adjustNodes, adjustNode)
                end
            end)
            self.scaleNodes = {}
            self.xmlFile:iterate("toolConnectionHoseMount.scaleNodes", function(_, baseKey)
                -- upvalues: (copy) self
                local scaleNode = {
                    ["node"] = self.xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings)
                }
                if scaleNode.node ~= nil then
                    table.insert(self.scaleNodes, scaleNode)
                end
            end)
            link(self.linkNode, self.node)
            setTranslation(self.node, self.translation[1], self.translation[2], self.translation[3])
            setRotation(self.node, self.rotation[1], self.rotation[2], self.rotation[3])
            self:createToolConnectionHoses()
            if self.lengthToSet ~= nil then
                self:setLength(self.lengthToSet)
            end
        end
        delete(i3dNode)
    end
    self.xmlFile:delete()
    self.xmlFile = nil
    self:onFinished(self.node ~= nil)
end
function ToolConnectionHoseMount:setLength(length)
    if self.node == nil then
        self.lengthToSet = length
    else
        self.lengthToSet = nil
        for _, adjustNode in ipairs(self.adjustNodes) do
            setTranslation(adjustNode.node, adjustNode.startTranslation[1], adjustNode.startTranslation[2], adjustNode.startTranslation[3] * (length / self.length))
        end
        for _, adjustNode in ipairs(self.scaleNodes) do
            setScale(adjustNode.node, 1, 1, scale)
        end
    end
end
function ToolConnectionHoseMount:addHoseTarget(node, sourceTarget, newType)
    local spec = self.vehicle.spec_connectionHoses
    local hoseTarget = {
        ["node"] = node,
        ["attacherJointIndices"] = sourceTarget.attacherJointIndices,
        ["type"] = newType,
        ["straighteningFactor"] = sourceTarget.straighteningFactor,
        ["adapterName"] = sourceTarget.adapterName,
        ["adapter"] = {}
    }
    hoseTarget.adapter.node = node
    hoseTarget.adapter.refNode = node
    hoseTarget.objectChanges = {}
    table.insert(spec.targetNodes, hoseTarget)
    hoseTarget.index = #spec.targetNodes
    if spec.targetNodesByType[hoseTarget.type] == nil then
        spec.targetNodesByType[hoseTarget.type] = {}
    end
    table.insert(spec.targetNodesByType[hoseTarget.type], hoseTarget)
    return hoseTarget.index
end
function ToolConnectionHoseMount:createToolConnectionHoses()
    for _, target in ipairs(self.targetNodes) do
        local newToolConnectionHose = {
            ["startTargetNodeIndex"] = self:addHoseTarget(target.frontNode, self.startTarget, target.typeName),
            ["endTargetNodeIndex"] = self:addHoseTarget(target.backNode, self.endTarget, target.typeName),
            ["mountingNode"] = target.mountingNode or self.node,
            ["moveNodes"] = target.moveNodes,
            ["additionalHose"] = target.createHose,
            ["additionalHoseOffset"] = target.hoseOffset,
            ["parentToolConnectionHose"] = self.parentToolConnectionHose,
            ["objectChanges"] = {},
            ["objectChangesTarget"] = self.vehicle,
            ["additionalHoses"] = self.additionalHoses
        }
        setVisibility(newToolConnectionHose.mountingNode, false)
        table.insert(self.vehicle.spec_connectionHoses.toolConnectorHoses, newToolConnectionHose)
        spec.targetNodeToToolConnection[newToolConnectionHose.startTargetNodeIndex] = newToolConnectionHose
        spec.targetNodeToToolConnection[newToolConnectionHose.endTargetNodeIndex] = newToolConnectionHose
    end
end
function ToolConnectionHoseMount.registerExternalXMLPaths(schema)
    schema:register(XMLValueType.STRING, "toolConnectionHoseMount.filename", "Path to i3d file", nil, true)
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.rootNode#node", "Node index", "0")
    schema:register(XMLValueType.FLOAT, "toolConnectionHoseMount.rootNode#length", "Length of the mount inside the file", 3)
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.target(?)#backNode", "Node for the back tool to connection to")
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.target(?)#frontNode", "Node for the front tool to connection to")
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.target(?)#mountingNode", "Custom node that is hidden when not active")
    schema:register(XMLValueType.STRING, "toolConnectionHoseMount.target(?)#typeName", "Name of the hose type")
    schema:register(XMLValueType.BOOL, "toolConnectionHoseMount.target(?)#createHose", "Create local hose between the front and back node")
    schema:register(XMLValueType.BOOL, "toolConnectionHoseMount.target(?)#moveNodes", "Move nodes up by the radius of the hose")
    schema:register(XMLValueType.FLOAT, "toolConnectionHoseMount.target(?)#hoseOffset", "Offset for the hose creation", 0)
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.hose(?)#startNode", "Start node of the local hose")
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.hose(?)#endNode", "End node of the local hose")
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.adjustNodes(?)#node", "Node that is adjusted to the length of the mount")
    schema:register(XMLValueType.NODE_INDEX, "toolConnectionHoseMount.scaleNodes(?)#node", "Node that is scaled based on the length of the mount")
    I3DUtil.registerI3dMappingXMLPaths(schema, "toolConnectionHoseMount")
end
g_xmlManager:addCreateSchemaFunction(function()
    ToolConnectionHoseMount.xmlSchema = XMLSchema.new("toolConnectionHoseMount")
end)
g_xmlManager:addInitSchemaFunction(function()
    ToolConnectionHoseMount.registerExternalXMLPaths(ToolConnectionHoseMount.xmlSchema)
end)