ChainsawCutEvent = {}
local ChainsawCutEvent_mt = Class(ChainsawCutEvent, Event)
InitStaticEventClass(ChainsawCutEvent, "ChainsawCutEvent")
function ChainsawCutEvent.emptyNew()
    -- upvalues: (copy) ChainsawCutEvent_mt
    return Event.new(ChainsawCutEvent_mt)
end
function ChainsawCutEvent.new(splitShapeId, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
    local self = ChainsawCutEvent.emptyNew()
    self.splitShapeId = splitShapeId
    self.x = x
    self.y = y
    self.z = z
    self.nx = nx
    self.ny = ny
    self.nz = nz
    self.yx = yx
    self.yy = yy
    self.yz = yz
    self.cutSizeY = cutSizeY
    self.cutSizeZ = cutSizeZ
    self.farmId = farmId
    return self
end
function ChainsawCutEvent.readStream(_, streamId, connection)
    if not connection:getIsServer() then
        local splitShapeId = readSplitShapeIdFromStream(streamId)
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        local nx = streamReadFloat32(streamId)
        local ny = streamReadFloat32(streamId)
        local nz = streamReadFloat32(streamId)
        local yx = streamReadFloat32(streamId)
        local yy = streamReadFloat32(streamId)
        local yz = streamReadFloat32(streamId)
        local cutSizeY = streamReadFloat32(streamId)
        local cutSizeZ = streamReadFloat32(streamId)
        local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        if splitShapeId ~= 0 then
            ChainsawUtil.cutSplitShape(splitShapeId, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
        end
    end
end
function ChainsawCutEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        writeSplitShapeIdToStream(streamId, self.splitShapeId)
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
        streamWriteFloat32(streamId, self.nx)
        streamWriteFloat32(streamId, self.ny)
        streamWriteFloat32(streamId, self.nz)
        streamWriteFloat32(streamId, self.yx)
        streamWriteFloat32(streamId, self.yy)
        streamWriteFloat32(streamId, self.yz)
        streamWriteFloat32(streamId, self.cutSizeY)
        streamWriteFloat32(streamId, self.cutSizeZ)
        streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
end
function ChainsawCutEvent:run(connection)
    print("Error: ChainsawCutEvent is not allowed to be executed on a local client")
end