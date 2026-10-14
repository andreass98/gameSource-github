ConstructibleState = {}
local ConstructibleState_mt = Class(ConstructibleState)
function ConstructibleState.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".toggleMesh(?)#node", "")
    schema:register(XMLValueType.BOOL, basePath .. ".toggleMesh(?)#active", "")
    schema:register(XMLValueType.BOOL, basePath .. ".toggleMesh(?)#updatePhysics", "", false)
    schema:register(XMLValueType.INT, basePath .. ".toggleHotspot(?)#index", "")
    schema:register(XMLValueType.BOOL, basePath .. ".toggleHotspot(?)#isVisible", "")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
end
function ConstructibleState.new(constructible, dirtyFlag, customMt)
    -- upvalues: (copy) ConstructibleState_mt
    local self = setmetatable({}, customMt or ConstructibleState_mt)
    self.constructible = constructible
    self.dirtyFlag = dirtyFlag
    self.toggleMeshes = {}
    self.isSoundPlaying = false
    return self
end
function ConstructibleState:load(xmlFile, key)
    self.name = string.upper(xmlFile:getValue(key .. "#name", ""))
    if self.constructible.isClient then
        self.samples = {}
        self.samples.active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", self.constructible.baseDirectory, self.constructible.components, 0, AudioGroup.ENVIRONMENT, self.constructible.i3dMappings, self)
    end
    for _, nodeKey in xmlFile:iterator(key .. ".toggleHotspot") do
        local hotspotIndex = xmlFile:getInt(nodeKey .. "#index")
        local isVisible = xmlFile:getBool(nodeKey .. "#isVisible")
        if hotspotIndex ~= nil and isVisible ~= nil then
            if self.toggleHotspots == nil then
                self.toggleHotspots = {}
            end
            table.insert(self.toggleHotspots, {
                ["index"] = hotspotIndex,
                ["isVisible"] = isVisible
            })
        end
    end
    for _, nodeKey in xmlFile:iterator(key .. ".toggleMesh") do
        local hotspotIndex = xmlFile:getValue(nodeKey .. "#node", nil, self.constructible.components, self.constructible.i3dMappings)
        if hotspotIndex ~= nil then
            local collision = {
                ["node"] = hotspotIndex,
                ["active"] = xmlFile:getValue(nodeKey .. "#active", true),
                ["physics"] = xmlFile:getValue(nodeKey .. "#updatePhysics", false)
            }
            table.insert(self.toggleMeshes, collision)
        end
    end
    self.objectChanges = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, nil, self.constructible.components, self.constructible)
end
function ConstructibleState:delete()
    if self.samples ~= nil then
        g_soundManager:deleteSamples(self.samples)
    end
end
function ConstructibleState:saveToXMLFile(xmlFile, key, usedModNames) end
function ConstructibleState:loadFromXMLFile(xmlFile, key) end
function ConstructibleState:onReadStream(streamId, connection) end
function ConstructibleState:onWriteStream(streamId, connection) end
function ConstructibleState:onReadUpdateStream(streamId, timestamp, connection) end
function ConstructibleState:onWriteUpdateStream(streamId, connection, dirtyMask) end
function ConstructibleState:update(_)
    if self.constructible.isClient and (self.samples ~= nil and self.samples.active ~= nil) then
        if self:getPlaySound() then
            if not self.isSoundPlaying then
                g_soundManager:playSample(self.samples.active)
                self.isSoundPlaying = true
                return
            end
        elseif self.isSoundPlaying then
            g_soundManager:stopSample(self.samples.active)
            self.isSoundPlaying = false
        end
    end
end
function ConstructibleState:activate()
    self.isSoundPlaying = false
    for _, toggleMesh in ipairs(self.toggleMeshes) do
        if toggleMesh.active then
            if toggleMesh.physics then
                addToPhysics(toggleMesh.node)
            end
            setVisibility(toggleMesh.node, true)
        else
            if toggleMesh.physics then
                removeFromPhysics(toggleMesh.node)
            end
            setVisibility(toggleMesh.node, false)
        end
    end
    if self.toggleHotspots ~= nil and self.constructible.setHotspotVisible ~= nil then
        for _, toggleMesh in ipairs(self.toggleHotspots) do
            self.constructible:setHotspotVisible(toggleMesh.index, toggleMesh.isVisible)
        end
        self.constructible:updateHotspots()
    end
    ObjectChangeUtil.setObjectChanges(self.objectChanges, true)
end
function ConstructibleState:deactivate()
    if self.constructible.isClient and (self.samples ~= nil and self.samples.active ~= nil) then
        g_soundManager:stopSample(self.samples.active)
    end
end
function ConstructibleState:reset()
    for _, toggleMesh in ipairs(self.toggleMeshes) do
        if toggleMesh.active then
            if toggleMesh.physics then
                removeFromPhysics(toggleMesh.node)
            end
            setVisibility(toggleMesh.node, false)
        else
            if toggleMesh.physics then
                addToPhysics(toggleMesh.node)
            end
            setVisibility(toggleMesh.node, true)
        end
    end
end
function ConstructibleState:isDone()
    return false
end
function ConstructibleState:raiseActive()
    return false
end
function ConstructibleState:getPlaySound()
    return true
end
function ConstructibleState:getIsConstructibleState()
    return true
end