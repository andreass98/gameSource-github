TreeAttachRequestEvent = {}
local TreeAttachRequestEvent_mt = Class(TreeAttachRequestEvent, Event)
InitStaticEventClass(TreeAttachRequestEvent, "TreeAttachRequestEvent")
function TreeAttachRequestEvent.emptyNew()
    -- upvalues: (copy) TreeAttachRequestEvent_mt
    return Event.new(TreeAttachRequestEvent_mt)
end
function TreeAttachRequestEvent.new(object, splitShapeId, x, y, z, ropeIndex, setupRope)
    local self = TreeAttachRequestEvent.emptyNew()
    self.object = object
    self.splitShapeId = splitShapeId
    self.x = x
    self.y = y
    self.z = z
    self.ropeIndex = ropeIndex
    self.setupRope = setupRope
    return self
end
function TreeAttachRequestEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self.x = streamReadFloat32(streamId)
    self.y = streamReadFloat32(streamId)
    self.z = streamReadFloat32(streamId)
    if streamReadBool(streamId) then
        self.ropeIndex = streamReadUIntN(streamId, 3)
    end
    if streamReadBool(streamId) then
        self.setupRopeData = ForestryPhysicsRope.readStream(streamId, true)
    end
    self:run(connection)
end
function TreeAttachRequestEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
    streamWriteFloat32(streamId, self.x)
    streamWriteFloat32(streamId, self.y)
    streamWriteFloat32(streamId, self.z)
    if streamWriteBool(streamId, self.ropeIndex ~= nil) then
        streamWriteUIntN(streamId, self.ropeIndex, 3)
    end
    if streamWriteBool(streamId, self.setupRope ~= nil) then
        self.setupRope:writeStream(streamId)
    end
end
function TreeAttachRequestEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object.getIsCarriageTreeAttachAllowed ~= nil then
            local isAllowed, reason = self.object:getIsCarriageTreeAttachAllowed(self.splitShapeId)
            if isAllowed then
                self.object:attachTreeToCarriage(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex)
            else
                g_server:broadcastEvent(TreeAttachResponseEvent.new(self.object, reason, self.ropeIndex), nil, nil, self.object, nil, { connection })
            end
        end
        if self.object.getIsWinchTreeAttachAllowed ~= nil then
            local isAllowed, reason = self.object:getIsWinchTreeAttachAllowed(self.ropeIndex, self.splitShapeId)
            if isAllowed then
                self.object:attachTreeToWinch(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex, self.setupRopeData)
                return
            end
            g_server:broadcastEvent(TreeAttachResponseEvent.new(self.object, reason, self.ropeIndex), nil, nil, self.object, nil, { connection })
        end
    end
end