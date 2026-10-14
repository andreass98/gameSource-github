TreeMarkerEvent = {}
local TreeMarkerEvent_mt = Class(TreeMarkerEvent, Event)
InitStaticEventClass(TreeMarkerEvent, "TreeMarkerEvent")
function TreeMarkerEvent.emptyNew()
    -- upvalues: (copy) TreeMarkerEvent_mt
    return Event.new(TreeMarkerEvent_mt)
end
function TreeMarkerEvent.new(treeMarkers)
    local self = TreeMarkerEvent.emptyNew()
    assert(#treeMarkers <= 255, "Max num of treemarkers per event is 255")
    self.treeMarkers = treeMarkers
    return self
end
function TreeMarkerEvent:readStream(streamId, connection)
    self.treeMarkers = {}
    local numMarkers = streamReadUInt8(streamId)
    for i = 1, numMarkers do
        local treeMarker = {
            ["splitShapeId"] = readSplitShapeIdFromStream(streamId),
            ["treeMarkerTypeIndex"] = streamReadUInt8(streamId),
            ["r"] = streamReadUInt8(streamId) / 255,
            ["g"] = streamReadUInt8(streamId) / 255,
            ["b"] = streamReadUInt8(streamId) / 255,
            ["a"] = streamReadUInt8(streamId) / 255,
            ["posX"] = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.treeMarkerSystem.xTreePosCompressionParams),
            ["posY"] = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.treeMarkerSystem.yTreePosCompressionParams),
            ["rotY"] = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2,
            ["scale"] = streamReadUIntN(streamId, 9) / 511
        }
        table.insert(self.treeMarkers, treeMarker)
    end
    self:run(connection)
end
function TreeMarkerEvent:writeStream(streamId, _)
    streamWriteUInt8(streamId, #self.treeMarkers)
    for _, treeMarker in ipairs(self.treeMarkers) do
        writeSplitShapeIdToStream(streamId, treeMarker.splitShapeId)
        streamWriteUInt8(streamId, treeMarker.treeMarkerTypeIndex)
        streamWriteUInt8(streamId, treeMarker.r * 255)
        streamWriteUInt8(streamId, treeMarker.g * 255)
        streamWriteUInt8(streamId, treeMarker.b * 255)
        streamWriteUInt8(streamId, treeMarker.a * 255)
        NetworkUtil.writeCompressedWorldPosition(streamId, treeMarker.posX, g_currentMission.treeMarkerSystem.xTreePosCompressionParams)
        NetworkUtil.writeCompressedWorldPosition(streamId, treeMarker.posY, g_currentMission.treeMarkerSystem.yTreePosCompressionParams)
        streamWriteUIntN(streamId, math.clamp(math.floor(treeMarker.rotY % 6.283185307179586 / 6.283185307179586 * 511), 0, 511), 9)
        streamWriteUIntN(streamId, math.floor(treeMarker.scale * 511), 9)
    end
end
function TreeMarkerEvent:run(_)
    for _, treeMarker in ipairs(self.treeMarkers) do
        g_currentMission.treeMarkerSystem:addTreeMarker(treeMarker.splitShapeId, treeMarker.treeMarkerTypeIndex, treeMarker.r, treeMarker.g, treeMarker.b, treeMarker.a, treeMarker.posX, treeMarker.posY, treeMarker.scale, treeMarker.rotY, true)
    end
end