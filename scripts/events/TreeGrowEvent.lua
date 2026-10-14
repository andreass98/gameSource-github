TreeGrowEvent = {}
local TreeGrowEvent_mt = Class(TreeGrowEvent, Event)
InitStaticEventClass(TreeGrowEvent, "TreeGrowEvent")
function TreeGrowEvent.emptyNew()
    -- upvalues: (copy) TreeGrowEvent_mt
    return Event.new(TreeGrowEvent_mt)
end
function TreeGrowEvent.new(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeFileId, oldSplitShapeFileId)
    local self = TreeGrowEvent.emptyNew()
    self.treeType = treeType
    self.x = x
    self.y = y
    self.z = z
    self.rx = rx
    self.ry = ry
    self.rz = rz
    self.growthStateI = growthStateI
    self.variationIndex = variationIndex
    self.splitShapeFileId = splitShapeFileId
    self.oldSplitShapeFileId = oldSplitShapeFileId
    return self
end
function TreeGrowEvent.readStream(_, streamId, connection)
    if connection:getIsServer() then
        local treeType = streamReadUInt8(streamId)
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        local rx = streamReadFloat32(streamId)
        local ry = streamReadFloat32(streamId)
        local rz = streamReadFloat32(streamId)
        local growthStateI = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
        local variationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
        local serverSplitShapeFileId = streamReadInt32(streamId)
        local oldServerSplitShapeFileId = streamReadInt32(streamId)
        local oldNodeId = g_treePlantManager:getClientTree(oldServerSplitShapeFileId)
        if oldNodeId ~= nil then
            delete(oldNodeId)
            g_treePlantManager:removeClientTree(serverSplitShapeFileId)
        end
        local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(treeType)
        if treeTypeDesc ~= nil then
            local nodeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, -1)
            setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
            g_treePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
        end
    end
end
function TreeGrowEvent:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteUInt8(streamId, self.treeType)
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
        streamWriteFloat32(streamId, self.rx)
        streamWriteFloat32(streamId, self.ry)
        streamWriteFloat32(streamId, self.rz)
        streamWriteUIntN(streamId, self.growthStateI, TreePlantManager.STAGE_NUM_BITS)
        streamWriteUIntN(streamId, self.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
        streamWriteInt32(streamId, self.splitShapeFileId)
        streamWriteInt32(streamId, self.oldSplitShapeFileId)
    end
end
function TreeGrowEvent:run(connection)
    printError("Error: TreeGrowEvent is not allowed to be executed on a local client")
end