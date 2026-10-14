Effect = {}
Effect.DEFAULT_UPDATE_DISTANCE = 175
local Effect_mt = Class(Effect)
function Effect.new(customMt)
    -- upvalues: (copy) Effect_mt
    local self = setmetatable({}, customMt or Effect_mt)
    self.deleteListeners = {}
    self.startRestriction = {}
    self.allowUpdate = true
    self.lastUpdateTime = 0
    return self
end
function Effect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
    if xmlFile:hasProperty(baseName) then
        self.parent = parent
        self.rootNodes = rootNodes
        self.configFileName = Utils.getNoNil(parent.configFileName, parent.xmlFilename)
        self.baseDirectory = parent.baseDirectory
        local filename = xmlFile:getValue(baseName .. "#filename")
        if filename == nil then
            if self:loadEffectAttributes(xmlFile, baseName, nil, rootNodes, i3dMapping) then
                self:transformEffectNode(xmlFile, baseName, nil)
                return self
            else
                Logging.xmlWarning(xmlFile, "Failed to load effect \'%s\' from node", baseName)
                return nil
            end
        else
            local arguments = Utils.getFilename(filename, self.baseDirectory)
            self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.effectI3DFileLoaded, self, {
                ["xmlFile"] = xmlFile,
                ["baseName"] = baseName,
                ["i3dMapping"] = i3dMapping,
                ["filename"] = arguments,
                ["node"] = nil
            })
            return self
        end
    else
        return nil
    end
end
function Effect:loadFromNode(node, parent)
    self.parent = parent
    self.baseDirectory = parent.baseDirectory
    self.configFileName = Utils.getNoNil(parent.configFileName, parent.xmlFilename)
    local filename = getUserAttribute(node, "filename")
    if filename == nil then
        if self:loadEffectAttributes(nil, nil, node) then
            self:transformEffectNode(nil, nil, node)
            return self
        else
            Logging.xmlWarning(parent.xmlFile, "Failed to load effect from node \'%s\'", getName(node))
            return nil
        end
    else
        local arguments = Utils.getFilename(filename, self.baseDirectory)
        self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(arguments, false, false, self.effectI3DFileLoaded, self, {
            ["xmlFile"] = nil,
            ["baseName"] = nil,
            ["i3dMapping"] = nil,
            ["filename"] = arguments,
            ["node"] = node
        })
        return self
    end
end
function Effect:effectI3DFileLoaded(i3dNode, _, args)
    if i3dNode ~= 0 then
        local xmlFile = args.xmlFile
        local baseName = args.baseName
        local node = args.node
        self.filename = args.filename
        if not self:loadEffectAttributes(xmlFile, baseName, node, i3dNode, args.i3dMapping) then
            Logging.xmlWarning(xmlFile, "Failed to load effect from file \'%s\'", baseName)
        end
        self:transformEffectNode(xmlFile, baseName, node)
        delete(i3dNode)
    end
end
function Effect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
    local useSelfAsEffectNode = Utils.getNoNil(Effect.getValue(xmlFile, key, node, "useSelfAsEffectNode"), false)
    self.prio = Utils.getNoNil(Effect.getValue(xmlFile, key, node, "prio"), 0)
    local effect = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, node, "effectNode"), i3dMapping)
    if effect == nil then
        if useSelfAsEffectNode then
            effect = node
        end
    end
    if effect == nil then
        self.node = Effect.getValue(xmlFile, key, node, "node", nil, i3dNode, i3dMapping)
        self.linkNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, node, "linkNode"), i3dMapping)
        if self.linkNode == nil then
            if node == nil then
                Logging.xmlWarning(xmlFile, "LinkNode is nil in \'%s\'", key)
            else
                Logging.xmlWarning(xmlFile, "LinkNode is nil in node attribute \'%s\'", getName(node))
            end
            return false
        end
        if self.node == nil then
            if node == nil then
                Logging.xmlWarning(xmlFile, "Node is nil in \'%s\'", key)
            else
                Logging.xmlWarning(xmlFile, "Node is nil in node attribute \'%s\'", getName(node))
            end
            return false
        end
        if self.node ~= nil and self.linkNode ~= nil then
            link(self.linkNode, self.node)
        end
    else
        self.node = effect
    end
    return true
end
function Effect:transformEffectNode(xmlFile, key, node)
    local x, y, z = Effect.getValue(xmlFile, key, node, "position")
    local rotX, rotY, rotZ = Effect.getValue(xmlFile, key, node, "rotation")
    local scaleX, scaleY, scaleZ = Effect.getValue(xmlFile, key, node, "scale")
    if x ~= nil and (y ~= nil and z ~= nil) then
        setTranslation(self.node, x, y, z)
    end
    if rotX ~= nil and (rotY ~= nil and rotZ ~= nil) then
        setRotation(self.node, rotX, rotY, rotZ)
    end
    if scaleX ~= nil and (scaleY ~= nil and scaleZ ~= nil) then
        setScale(self.node, scaleX, scaleY, scaleZ)
    end
    setVisibility(self.node, false)
end
function Effect:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
    local i = #self.deleteListeners
    for i = i, 1, -1 do
        local listener = self.deleteListeners[i]
        listener.func(unpack(listener.args))
        self.deleteListeners[i] = nil
    end
    self.parent = nil
end
function Effect:update(dt) end
function Effect:isRunning()
    return false
end
function Effect:setUpdateDistance(maxUpdateDistance)
    if self.parent == nil then
        return
    elseif self.parent.currentUpdateDistance ~= nil then
        if maxUpdateDistance == math.huge then
            maxUpdateDistance = nil
        end
        self.maxUpdateDistance = maxUpdateDistance
    end
end
function Effect:getAllowUpdate()
    return self.maxUpdateDistance == nil or self.parent.currentUpdateDistance < self.maxUpdateDistance
end
function Effect:canStart()
    local canTurnOn = true
    local i = #self.startRestriction
    for i = i, 1, -1 do
        if canTurnOn then
            canTurnOn = self.startRestriction[i].func(unpack(restriction.args))
        end
    end
    return canTurnOn
end
function Effect:start()
    return false
end
function Effect:stop()
    return false
end
function Effect:reset() end
function Effect:getIsVisible()
    return true
end
function Effect:getIsFullyVisible()
    return true
end
function Effect.getValue(xmlFile, key, node, name, ...)
    if node == nil then
        return xmlFile:getValue(key .. "#" .. name, ...)
    else
        return getUserAttribute(node, name)
    end
end
function Effect:addDeleteListener(func, ...)
    table.insert(self.deleteListeners, {
        ["func"] = func,
        ["args"] = { ... }
    })
end
function Effect:addStartRestriction(func, ...)
    table.insert(self.startRestriction, {
        ["func"] = func,
        ["args"] = { ... }
    })
end
function Effect.registerEffectXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Effect from external i3d")
    schema:register(XMLValueType.BOOL, basePath .. "#shared", "Load i3d file as shared file")
    schema:register(XMLValueType.BOOL, basePath .. "#useSelfAsEffectNode", "Use root node as effect node", false)
    schema:register(XMLValueType.INT, basePath .. "#prio", "Prio", 0)
    schema:register(XMLValueType.STRING, basePath .. "#effectNode", "Effect node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Effect in i3d node")
    schema:register(XMLValueType.STRING, basePath .. "#linkNode", "Link node")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Translation")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation")
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. "#scale", "Scale")
end