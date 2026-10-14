TreePlantManager = {}
TreePlantManager.DECAY_INTERVAL = 60000
TreePlantManager.DECAY_DURATION = 7200000
TreePlantManager.DECAY_DURATION_INV = 1 / TreePlantManager.DECAY_DURATION
TreePlantManager.MAX_NUM_TYPES = 255
TreePlantManager.STAGE_NUM_BITS = 5
TreePlantManager.MAX_NUM_STAGES = TreePlantManager.STAGE_NUM_BITS ^ 2 - 1
TreePlantManager.VARIATION_NUM_BITS = 3
TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE = TreePlantManager.VARIATION_NUM_BITS ^ 2 - 1
local TreePlantManager_mt = Class(TreePlantManager, AbstractManager)
g_xmlManager:addInitSchemaFunction(function()
    local missionXMLSchema = Mission00.xmlSchema
    missionXMLSchema:register(XMLValueType.STRING, "map.treeTypes#filename", "")
    missionXMLSchema:register(XMLValueType.INT, "map.treeTypes#maxNumTrees", "", 8000)
end)
function TreePlantManager.new(customMt)
    -- upvalues: (copy) TreePlantManager_mt
    return AbstractManager.new(customMt or TreePlantManager_mt)
end
function TreePlantManager:initDataStructures()
    self.treeTypes = {}
    self.indexToTreeType = {}
    self.splitTypeIndexToTreeType = {}
    self.nameToTreeType = {}
    self.treeFileCache = {}
    self.loadTreeTrunkDatas = {}
    self.numTreesWithoutSplits = 0
    self.activeDecayingSplitShapes = {}
    self.updateDecayDtGame = 0
end
function TreePlantManager:initialize()
    local rootNode = createTransformGroup("trees")
    link(getRootNode(), rootNode)
    self.treesData = {}
    self.treesData.rootNode = rootNode
    self.treesData.growingTrees = {}
    self.treesData.splitTrees = {}
    self.treesData.clientTrees = {}
    self.treesData.updateDtGame = 0
    self.treesData.treeCutJoints = {}
    self.treesData.numTreesWithoutSplits = 0
end
function TreePlantManager:deleteTreesData()
    if self.treesData ~= nil then
        delete(self.treesData.rootNode)
        self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - self.treesData.numTreesWithoutSplits, 0)
        self:initDataStructures()
    end
end
function TreePlantManager:loadDefaultTypes(missionInfo, baseDirectory)
    local xmlFile = loadXMLFile("treeTypes", "data/maps/maps_treeTypes.xml")
    self:loadTreeTypes(xmlFile, missionInfo, baseDirectory, true)
    delete(xmlFile)
end
function TreePlantManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    TreePlantManager:superClass().loadMapData(self)
    if g_server ~= nil and g_addCheatCommands then
        addConsoleCommand("gsTreeCut", "Cut all trees around a given radius", "consoleCommandCutTrees", self, "[radius]")
        addConsoleCommand("gsTreeAdd", "Load a loose tree trunk", "consoleCommandLoadTree", self, "length; treeType; [growthState]; [delimb]")
        addConsoleCommand("gsTreePlant", "Plant given number of trees of a specified type", "consoleCommandPlantTrees", self, "treeType; number; growthState; variationIndex; isGrowing")
        addConsoleCommand("gsTreeLoadAll", "Spawn all trees in front of player", "consoleCommandLoadAll", self)
        addConsoleCommand("gsTreeRemove", "Remove currently looked at split shape or tree", "consoleCommandRemoveSplitShape", self)
    end
    if g_addCheatCommands then
        addConsoleCommand("gsTreeDebug", "Toggle tree/splitshape debug mode", "consoleCommandDebug", self)
    end
    self.maxNumTrees = math.clamp(getXMLInt(xmlFile, "map.treeTypes#maxNumTrees") or 8000, 1, 30000)
    g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, TreePlantManager.onMissionStarted, self)
    self:loadDefaultTypes(missionInfo, baseDirectory)
    return XMLUtil.loadDataFromMapXML(xmlFile, "treeTypes", baseDirectory, self, self.loadTreeTypes, missionInfo, baseDirectory)
end
function TreePlantManager:unloadMapData()
    for i3dFilename, requestId in pairs(self.treeFileCache) do
        g_i3DManager:releaseSharedI3DFile(requestId)
        self.treeFileCache[i3dFilename] = true
    end
    removeConsoleCommand("gsTreeCut")
    removeConsoleCommand("gsTreeAdd")
    removeConsoleCommand("gsTreePlant")
    removeConsoleCommand("gsTreeLoadAll")
    removeConsoleCommand("gsTreeRemove")
    removeConsoleCommand("gsTreeDebug")
    self:deleteTreesData()
    g_messageCenter:unsubscribe(MessageType.CURRENT_MISSION_START, self)
    TreePlantManager:superClass().unloadMapData(self)
end
function TreePlantManager:onMissionStarted(_)
    local numTotal, numSplit = getNumOfSplitShapes()
    Logging.info("TreePlantManager - NumTrees %d (%d split) / MaxNumTrees: %d", numTotal, numSplit, self.maxNumTrees)
end
function TreePlantManager:loadTreeTypes(xmlFile, _, baseDirectory, isBaseType, customEnvironment)
    if type(xmlFile) == "number" then
        xmlFile = XMLFile.wrap(xmlFile)
    end
    for _, treeTypeKey in xmlFile:iterator("map.treeTypes.treeType") do
        local name = xmlFile:getString(treeTypeKey .. "#name")
        local title = xmlFile:getString(treeTypeKey .. "#title")
        local growthTimeHours = xmlFile:getString(treeTypeKey .. "#growthTimeHours")
        local splitTypeName = xmlFile:getString(treeTypeKey .. "#splitType")
        local supportsPlanting = xmlFile:getBool(treeTypeKey .. "#supportsPlanting", true)
        local saplingPrice = xmlFile:getFloat(treeTypeKey .. "#saplingPrice", 0)
        if name == nil then
            Logging.xmlWarning(xmlFile, "Missing \'name\' attribute for treeType %q", treeTypeKey)
        elseif title == nil then
            Logging.xmlWarning(xmlFile, "Missing \'title\' attribute for treeType %q", treeTypeKey)
        elseif growthTimeHours == nil then
            Logging.xmlWarning(xmlFile, "Missing \'growthTimeHours\' attribute for treeType %q", treeTypeKey)
        elseif splitTypeName == nil then
            Logging.xmlWarning(xmlFile, "Missing \'splitType\' attribute for treeType %q", treeTypeKey)
        else
            local splitTypeIndex = g_splitShapeManager:getSplitTypeIndexByName(splitTypeName)
            if splitTypeIndex == nil then
                Logging.xmlWarning(xmlFile, "SplitType \'%s\' not defined for treeType %q", splitTypeName, treeTypeKey)
            else
                local stages = {}
                for _, stageKey in xmlFile:iterator(treeTypeKey .. ".stage") do
                    local filename = xmlFile:getString(stageKey .. "#filename")
                    if filename == nil then
                        local variation = {}
                        for _, variationKey in xmlFile:iterator(stageKey .. ".variation") do
                            local variation = xmlFile:getString(variationKey .. "#filename")
                            if variation ~= nil then
                                if #variation >= TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE then
                                    Logging.xmlWarning(xmlFile, "Unable to add variation %q for tree %q, max number of variations per stage (%d) reached", variation, name, TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE)
                                    break
                                end
                                local variation = {
                                    ["name"] = xmlFile:getString(variationKey .. "#name"),
                                    ["filename"] = Utils.getFilename(variation, baseDirectory)
                                }
                                local palletFilename = xmlFile:getString(variationKey .. ".pallet#filename")
                                if palletFilename ~= nil then
                                    variation.palletFilename = Utils.getFilename(palletFilename, baseDirectory)
                                end
                                local palletStoreItemFilename = xmlFile:getString(variationKey .. ".pallet#storeItem")
                                if palletStoreItemFilename ~= nil then
                                    variation.palletStoreItemFilename = Utils.getFilename(palletStoreItemFilename, baseDirectory)
                                end
                                local planterFilename = xmlFile:getString(variationKey .. ".planter#filename")
                                if planterFilename ~= nil then
                                    variation.planterFilename = Utils.getFilename(planterFilename, baseDirectory)
                                end
                                table.insert(variation, variation)
                            end
                        end
                        if #stages >= TreePlantManager.MAX_NUM_STAGES then
                            Logging.xmlWarning(xmlFile, "Unable to add stage %q for tree %q, max number of stages (%d) reached", stageKey, name, TreePlantManager.MAX_NUM_STAGES)
                        end
                        table.insert(stages, variation)
                    else
                        local variation = {
                            ["filename"] = Utils.getFilename(filename, baseDirectory)
                        }
                        local palletFilename = xmlFile:getString(stageKey .. ".pallet#filename")
                        if palletFilename ~= nil then
                            variation.palletFilename = Utils.getFilename(palletFilename, baseDirectory)
                        end
                        local palletStoreItemFilename = xmlFile:getString(stageKey .. ".pallet#storeItem")
                        if palletStoreItemFilename ~= nil then
                            variation.palletStoreItemFilename = Utils.getFilename(palletStoreItemFilename, baseDirectory)
                        end
                        local planterFilename = xmlFile:getString(stageKey .. ".planter#filename")
                        if planterFilename ~= nil then
                            variation.planterFilename = Utils.getFilename(planterFilename, baseDirectory)
                        end
                        table.insert(stages, { variation })
                    end
                end
                if #stages == 0 then
                    Logging.xmlWarning(xmlFile, "A treetype %q (%s) has no valid stages defined\'", name, treeTypeKey)
                else
                    self:registerTreeType(name, g_i18n:convertText(title, customEnvironment), stages, growthTimeHours, isBaseType, splitTypeIndex, supportsPlanting, saplingPrice)
                end
            end
        end
    end
    return true
end
function TreePlantManager:registerTreeType(name, title, stages, growthTimeHours, isBaseType, splitTypeIndex, supportsPlanting, saplingPrice)
    local treeType = string.upper(name)
    if #self.treeTypes >= TreePlantManager.MAX_NUM_TYPES then
        Logging.warning("Unable to register tree type %q, maximum number of tree types (%d) reached", treeType, TreePlantManager.MAX_NUM_TYPES)
        return nil
    end
    if isBaseType and self.nameToTreeType[treeType] ~= nil then
        Logging.warning("TreeType %q already exists. Ignoring treeType!", treeType)
        return nil
    end
    local treeType = self.nameToTreeType[treeType]
    if treeType == nil then
        treeType = {
            ["name"] = treeType,
            ["title"] = title,
            ["index"] = #self.treeTypes + 1,
            ["splitTypeIndex"] = splitTypeIndex
        }
        table.insert(self.treeTypes, treeType)
        self.indexToTreeType[treeType.index] = treeType
        self.nameToTreeType[treeType] = treeType
        self.splitTypeIndexToTreeType[splitTypeIndex] = treeType
    end
    treeType.stages = stages
    treeType.growthTimeHours = growthTimeHours
    treeType.supportsPlanting = supportsPlanting
    if supportsPlanting then
        treeType.saplingPrice = saplingPrice
    end
    return treeType
end
function TreePlantManager.getTreeTypeFilename(_, treeTypeDesc, growthStateI)
    if treeTypeDesc == nil then
        return nil
    end
    local stage = treeTypeDesc.stages[math.min(growthStateI, #treeTypeDesc.stages)]
    return stage[math.random(1, #stage)].filename
end
function TreePlantManager:canPlantTree()
    local totalNumSplit, numSplit = getNumOfSplitShapes()
    return totalNumSplit - numSplit + self.numTreesWithoutSplits < self.maxNumTrees
end
function TreePlantManager:plantTree(treeTypeIndex, x, y, z, rx, ry, rz, growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, existingSplitShapeFileId)
    local treeTypeDesc = self.indexToTreeType[treeTypeIndex]
    if treeTypeDesc == nil then
        return nil
    end
    local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, existingSplitShapeFileId)
    if treeId == 0 then
        return nil
    end
    local tree = {
        ["node"] = treeId,
        ["growthStateI"] = growthStateI,
        ["variationIndex"] = variationIndex or 1
    }
    tree.isGrowing = Utils.getNoNil(isGrowing, true) and growthStateI < #treeTypeDesc.stages
    tree.x = x
    tree.y = y
    tree.z = z
    tree.rx = rx
    tree.ry = ry
    tree.rz = rz
    tree.treeType = treeTypeIndex
    tree.splitShapeFileId = splitShapeFileId
    tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
    if tree.isGrowing then
        tree.origSplitShape = getChildAt(treeId, 0)
        if nextGrowthTargetHour == nil then
            tree.nextGrowthTargetHour = g_currentMission.environment:getMonotonicHour() + treeTypeDesc.growthTimeHours
        else
            tree.nextGrowthTargetHour = nextGrowthTargetHour
        end
        table.insert(self.treesData.growingTrees, tree)
    else
        table.insert(treesData.splitTrees, tree)
    end
    if not tree.hasSplitShapes then
        self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
        treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
    end
    g_server:broadcastEvent(TreePlantEvent.new(treeTypeIndex, x, y, z, rx, ry, rz, growthStateI, tree.variationIndex, splitShapeFileId, tree.isGrowing))
    return treeId
end
function TreePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeLoadingFileId)
    local stage = math.min(growthStateI, #treeTypeDesc.stages)
    local variations = treeTypeDesc.stages[stage]
    if variations == nil then
        Logging.error("TreePlantManager:loadTreeNode failed due to invalid stage index (stage %d of %d)", stage, #treeTypeDesc.stages)
        return 0
    end
    local requestId = #variations
    local i3dFilename = variations[math.clamp(variationIndex, 1, requestId)].filename
    if self.treeFileCache[i3dFilename] == nil then
        setSplitShapesLoadingFileId(-1)
        setSplitShapesNextFileId(true)
        local node, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
        if node ~= 0 then
            delete(node)
            self.treeFileCache[i3dFilename] = requestId
        end
    end
    setSplitShapesLoadingFileId(splitShapeLoadingFileId or -1)
    local node = setSplitShapesNextFileId()
    local requestId, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
    g_i3DManager:releaseSharedI3DFile(requestId)
    if requestId ~= 0 then
        link(self.treesData.rootNode, requestId)
        setTranslation(requestId, x, y, z)
        setRotation(requestId, rx, ry, rz)
        local i = 0
        for i = i, getNumOfChildren(requestId) - 1 do
            local child = getChildAt(requestId, i)
            if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) and getIsSplitShapeSplit(child) then
                setWorldRotation(child, getRotation(child))
                setWorldTranslation(child, getTranslation(child))
            end
        end
        I3DUtil.iterateRecursively(requestId, function(node, _)
            -- upvalues: (copy) treeTypeDesc, (copy) i3dFilename
            if getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
                local splitTypeIndex = getSplitType(node)
                if splitTypeIndex ~= treeTypeDesc.splitTypeIndex then
                    Logging.warning("Tree has wrong splitType \'%s\' assigned. Should be \'%s\'. File: \'%s\'", splitTypeIndex, treeTypeDesc.splitTypeIndex, i3dFilename)
                end
                if g_server == nil and getRigidBodyType(node) == RigidBodyType.DYNAMIC then
                    setRigidBodyType(node, RigidBodyType.KINEMATIC)
                end
            end
            return true
        end)
        addToPhysics(requestId)
    end
    g_densityMapHeightManager:setCollisionMapAreaDirty(x - 2, z - 2, x + 2, z + 2, true)
    g_currentMission.aiSystem:setAreaDirty(x - 2, x + 2, z - 2, z + 2)
    return requestId, node
end
function TreePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthStateI, variationIndex, delimb, useOnlyStump)
    local treeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, 0, 0, 0, growthStateI, variationIndex)
    if treeId ~= 0 then
        if getFileIdHasSplitShapes(splitShapeFileId) then
            local tree = {
                ["node"] = treeId,
                ["growthStateI"] = growthStateI,
                ["variationIndex"] = variationIndex,
                ["x"] = x,
                ["y"] = y,
                ["z"] = z,
                ["rx"] = 0,
                ["ry"] = 0,
                ["rz"] = 0,
                ["treeType"] = treeTypeDesc.index,
                ["splitShapeFileId"] = splitShapeFileId,
                ["hasSplitShapes"] = getFileIdHasSplitShapes(splitShapeFileId)
            }
            table.insert(self.treesData.splitTrees, tree)
            table.insert(self.loadTreeTrunkDatas, {
                ["framesLeft"] = 2,
                ["shape"] = treeId + 2,
                ["x"] = x,
                ["y"] = y,
                ["z"] = z,
                ["length"] = length,
                ["offset"] = 0.5,
                ["dirX"] = dirX,
                ["dirY"] = dirY,
                ["dirZ"] = dirZ,
                ["delimb"] = delimb,
                ["useOnlyStump"] = useOnlyStump,
                ["cutTreeTrunkCallback"] = TreePlantManager.cutTreeTrunkCallback
            })
            return
        end
        delete(treeId)
    end
end
function TreePlantManager.cutTreeTrunkCallback(loadTreeTrunkData, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    g_treePlantManager:addingSplitShape(shape, loadTreeTrunkData.shapeBeingCut)
    table.insert(loadTreeTrunkData.parts, {
        ["shape"] = shape,
        ["isBelow"] = isBelow,
        ["isAbove"] = isAbove,
        ["minY"] = minY,
        ["maxY"] = maxY,
        ["minZ"] = minZ,
        ["maxZ"] = maxZ
    })
end
function TreePlantManager:updateTrees(_, dtGame)
    local treesData = self.treesData
    treesData.updateDtGame = treesData.updateDtGame + dtGame
    if treesData.updateDtGame > 3600000 then
        self:cleanupDeletedTrees()
        treesData.updateDtGame = 0
        local currentMonotonicHour = g_currentMission.environment:getMonotonicHour()
        local numGrowingTrees = #treesData.growingTrees
        local i = 1
        while i <= numGrowingTrees do
            local tree = treesData.growingTrees[i]
            if getChildAt(tree.node, 0) == tree.origSplitShape then
                local treeTypeDesc = self.indexToTreeType[tree.treeType]
                local numStages = #treeTypeDesc.stages
                if tree.nextGrowthTargetHour < currentMonotonicHour then
                    local treeId = #treeTypeDesc.stages
                    local growthStateNew = math.min(tree.growthStateI + 1, treeId)
                    if self.debugActive then
                        Logging.info("growing tree %s from stage %d to %d", treeTypeDesc.name, tree.growthStateI, growthStateNew)
                    end
                    tree.growthStateI = growthStateNew
                    if numStages <= tree.growthStateI then
                        tree.nextGrowthTargetHour = nil
                    else
                        tree.nextGrowthTargetHour = currentMonotonicHour + treeTypeDesc.growthTimeHours
                    end
                    delete(tree.node)
                    if not tree.hasSplitShapes then
                        self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
                        treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
                    end
                    tree.variationIndex = math.random(1, #treeTypeDesc.stages[tree.growthStateI])
                    local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthStateI, tree.variationIndex, -1)
                    g_server:broadcastEvent(TreeGrowEvent.new(tree.treeType, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthStateI, tree.variationIndex, splitShapeFileId, tree.splitShapeFileId))
                    tree.origSplitShape = getChildAt(treeId, 0)
                    tree.splitShapeFileId = splitShapeFileId
                    tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
                    tree.node = treeId
                    local x, _, z = getWorldTranslation(treeId)
                    g_densityMapHeightManager:setCollisionMapAreaDirty(x - 2.5, z - 2.5, x + 2.5, z + 2.5, true)
                    g_currentMission.aiSystem:setAreaDirty(x - 2.5, x + 2.5, z - 2.5, z + 2.5)
                    if not tree.hasSplitShapes then
                        self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
                        treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
                    end
                end
                if numStages <= tree.growthStateI then
                    if self.debugActive then
                        Logging.info("Removing fully grown tree %d (%s stage %d) from growth", tree.node, treeTypeDesc.name, tree.growthStateI)
                    end
                    table.remove(treesData.growingTrees, i)
                    numGrowingTrees = numGrowingTrees - 1
                    tree.origSplitShape = nil
                    table.insert(treesData.splitTrees, tree)
                else
                    i = i + 1
                end
            else
                if self.debugActive then
                    Logging.info("Removing cut tree %d from growing trees", tree.node)
                end
                table.remove(treesData.growingTrees, i)
                numGrowingTrees = numGrowingTrees - 1
                tree.origSplitShape = nil
                table.insert(treesData.splitTrees, tree)
            end
        end
    end
    local currentMonotonicHour = g_currentMission.time
    for treeTypeDesc in pairs(treesData.treeCutJoints) do
        if treeTypeDesc.destroyTime <= currentMonotonicHour or not entityExists(treeTypeDesc.shape) then
            removeJoint(treeTypeDesc.jointIndex)
            treesData.treeCutJoints[treeTypeDesc] = nil
        else
            local growthStateNew, variations, treeId = localDirectionToWorld(treeTypeDesc.shape, treeTypeDesc.lnx, treeTypeDesc.lny, treeTypeDesc.lnz)
            if growthStateNew * treeTypeDesc.nx + variations * treeTypeDesc.ny + treeId * treeTypeDesc.nz < treeTypeDesc.maxCosAngle then
                removeJoint(treeTypeDesc.jointIndex)
                treesData.treeCutJoints[treeTypeDesc] = nil
            end
        end
    end
    if #self.loadTreeTrunkDatas > 0 then
        local tree = #self.loadTreeTrunkDatas
        for tree = tree, 1, -1 do
            local treeTypeDesc = self.loadTreeTrunkDatas[tree]
            treeTypeDesc.framesLeft = treeTypeDesc.framesLeft - 1
            if treeTypeDesc.framesLeft == 1 then
                local _ = treeTypeDesc.y
                treeTypeDesc.parts = {}
                local shape = treeTypeDesc.shape
                if shape ~= nil and shape ~= 0 then
                    treeTypeDesc.shapeBeingCut = shape
                    splitShape(shape, treeTypeDesc.x + 1, _ + treeTypeDesc.length + treeTypeDesc.offset, treeTypeDesc.z - 1, 0, 1, 0, -1, 0, 0, 4, 4, "cutTreeTrunkCallback", treeTypeDesc)
                    self:removingSplitShape(shape)
                    for _, p in pairs(treeTypeDesc.parts) do
                        if p.isAbove then
                            delete(p.shape)
                        else
                            treeTypeDesc.shape = p.shape
                        end
                    end
                end
            elseif treeTypeDesc.framesLeft == 0 then
                local _ = treeTypeDesc.y
                treeTypeDesc.parts = {}
                local shape = treeTypeDesc.shape
                if shape ~= nil and shape ~= 0 then
                    splitShape(shape, treeTypeDesc.x + 1, _ + treeTypeDesc.offset, treeTypeDesc.z - 1, 0, 1, 0, -1, 0, 0, 5, 5, "cutTreeTrunkCallback", treeTypeDesc)
                    if treeTypeDesc.useOnlyStump then
                        for p, p in pairs(treeTypeDesc.parts) do
                            if not p.isBelow then
                                delete(p.shape)
                            end
                        end
                    else
                        local finalShape = nil
                        for p, p in pairs(treeTypeDesc.parts) do
                            if p.isBelow then
                                delete(p.shape)
                            else
                                finalShape = p.shape
                            end
                        end
                        if finalShape == nil then
                            Logging.error("Unable to cut tree trunk with length \'%s\'. Try using a different value", treeTypeDesc.length)
                        else
                            if treeTypeDesc.delimb then
                                removeSplitShapeAttachments(finalShape, x, _ + treeTypeDesc.offset, z, 0, 1, 0, -1, 0, 0, treeTypeDesc.length, 4, 4)
                            end
                            removeFromPhysics(finalShape)
                            setDirection(finalShape, 0, -1, 0, treeTypeDesc.dirX, treeTypeDesc.dirY, treeTypeDesc.dirZ)
                            addToPhysics(finalShape)
                        end
                    end
                end
                table.remove(self.loadTreeTrunkDatas, tree)
            end
        end
    end
    if self.commandCutTreeData ~= nil then
        if #self.commandCutTreeData.trees > 0 then
            local numGrowingTrees = self.commandCutTreeData.trees[1]
            local i, tree, treeTypeDesc = getWorldTranslation(numGrowingTrees)
            local numStages, growthStateNew, variations = worldToLocal(numGrowingTrees, i, tree + 0.5, treeTypeDesc)
            local treeId, splitShapeFileId, range = localToWorld(numGrowingTrees, numStages - 2, growthStateNew, variations - 2)
            local x, _, z = localDirectionToWorld(numGrowingTrees, 0, 1, 0)
            local shape, cutDiameter, finalShape = localDirectionToWorld(numGrowingTrees, 0, 0, 1)
            self.commandCutTreeData.shapeBeingCut = numGrowingTrees
            Logging.info("Cut tree \'%s\' (%d left)", getName(numGrowingTrees), #self.commandCutTreeData.trees - 1)
            splitShape(numGrowingTrees, treeId, splitShapeFileId, range, x, _, z, shape, cutDiameter, finalShape, 4, 4, "onTreeCutCommandSplitCallback", self)
            table.remove(self.commandCutTreeData.trees, 1)
        else
            self.commandCutTreeData = nil
        end
    end
    self.updateDecayDtGame = self.updateDecayDtGame + dtGame
    if self.updateDecayDtGame > TreePlantManager.DECAY_INTERVAL then
        for treeTypeDesc, numStages in pairs(self.activeDecayingSplitShapes) do
            if entityExists(treeTypeDesc) then
                if numStages.state > 0 then
                    local growthStateNew = math.max(numStages.state - TreePlantManager.DECAY_DURATION_INV * self.updateDecayDtGame, 0)
                    self:setSplitShapeLeafScaleAndVariation(treeTypeDesc, growthStateNew, numStages.variation)
                    self.activeDecayingSplitShapes[treeTypeDesc].state = growthStateNew
                end
            else
                self.activeDecayingSplitShapes[treeTypeDesc] = nil
            end
        end
        self.updateDecayDtGame = 0
    end
end
function TreePlantManager:drawDebug()
    if self.treesData ~= nil and self.treesData.growingTrees ~= nil then
        for index, tree in ipairs(self.treesData.growingTrees) do
            DebugText.renderAtNode(tree.node, string.format("growingTree #%d\ntype %s\ngrowthStateI %d\nvariation %d\nnextGrowthTargetHour %.2f", index, self.indexToTreeType[tree.treeType].name, tree.growthStateI, tree.variationIndex, tree.nextGrowthTargetHour), Color.PRESETS.GREEN, 0.01)
        end
        for index, tree in ipairs(self.treesData.splitTrees) do
            DebugText.renderAtNode(tree.node, string.format("splitTree #%d\ntype %s\ngrowthStateI %d\nvariation %d\n", index, self.indexToTreeType[tree.treeType].name, tree.growthStateI, tree.variationIndex), nil, 0.01)
        end
        for index, tree in pairs(self.treesData.clientTrees) do
            local treeTypeDesc = EnumUtil.getName(RigidBodyType, self:getTreeRigidBodyType(tree) or RigidBodyType.NONE)
            DebugText.renderAtNode(tree, string.format("clientTree\nserverSplitShapeFileId %s\nnodeId %s|%s\nRigidBodyType %s", index, tree, getName(tree), treeTypeDesc), nil, 0.01)
        end
    end
end
function TreePlantManager:addTreeCutJoint(jointIndex, shape, nx, ny, nz, maxAngle, maxLifetime)
    local lnx, lny, lnz = worldDirectionToLocal(shape, nx, ny, nz)
    local joint = {
        ["jointIndex"] = jointIndex,
        ["shape"] = shape,
        ["nx"] = nx,
        ["ny"] = ny,
        ["nz"] = nz,
        ["lnx"] = lnx,
        ["lny"] = lny,
        ["lnz"] = lnz,
        ["maxCosAngle"] = math.cos(maxAngle),
        ["destroyTime"] = g_currentMission.time + maxLifetime
    }
    self.treesData.treeCutJoints[joint] = joint
end
function TreePlantManager:getIsTreeDeleted(node)
    local i = 1
    local child = getNumOfChildren(node)
    for i = i, child do
        local child = getChildAt(node, i - 1)
        if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) or getHasClassId(child, ClassIds.SHAPE) then
            return false
        end
        if not self:getIsTreeDeleted(child) then
            return false
        end
    end
    return true
end
function TreePlantManager:getTreeRigidBodyType(node)
    local i = 1
    local child = getNumOfChildren(node)
    for i = i, child do
        local child = getChildAt(node, i - 1)
        if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) then
            return getRigidBodyType(child)
        end
        local rigidBodyType = self:getTreeRigidBodyType(child)
        if rigidBodyType ~= nil then
            return rigidBodyType
        end
    end
    return nil
end
function TreePlantManager:cleanupDeletedTrees()
    local treesData = self.treesData
    local numGrowingTrees = #treesData.growingTrees
    local growingTreeIndex = 1
    while growingTreeIndex <= numGrowingTrees do
        local tree = treesData.growingTrees[growingTreeIndex]
        if self:getIsTreeDeleted(tree.node) then
            table.remove(treesData.growingTrees, growingTreeIndex)
            numGrowingTrees = numGrowingTrees - 1
            delete(tree.node)
            if not tree.hasSplitShapes then
                self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
                treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
            end
        else
            growingTreeIndex = growingTreeIndex + 1
        end
    end
    local tree = #treesData.splitTrees
    local splitTreeIndex = 1
    while splitTreeIndex <= tree do
        local tree = treesData.splitTrees[splitTreeIndex]
        if self:getIsTreeDeleted(tree.node) then
            table.remove(treesData.splitTrees, splitTreeIndex)
            tree = tree - 1
            delete(tree.node)
            if not tree.hasSplitShapes then
                self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
                treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
            end
        else
            splitTreeIndex = splitTreeIndex + 1
        end
    end
end
function TreePlantManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end
    local xmlFile = loadXMLFile("treePlantXML", xmlFilename)
    if xmlFile == 0 then
        return false
    end
    local i = 0
    while true do
        local key = string.format("treePlant.tree(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local treeTypeName = getXMLString(xmlFile, key .. "#treeType")
        local treeType = self.nameToTreeType[treeTypeName]
        local pos = string.getVector(getXMLString(xmlFile, key .. "#position"), 3)
        local rot = string.getRadians(getXMLString(xmlFile, key .. "#rotation"), 3)
        if #pos == 3 and (#rot == 3 and treeType ~= nil) then
            local growthStateI = getXMLInt(xmlFile, key .. "#growthStateI")
            local variationIndex = getXMLInt(xmlFile, key .. "#variationIndex") or 1
            local nextGrowthTargetHour = getXMLFloat(xmlFile, key .. "#nextGrowthTargetHour")
            local isGrowing = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isGrowing"), true)
            local splitShapeFileId = getXMLInt(xmlFile, key .. "#splitShapeFileId")
            self:plantTree(treeType.index, pos[1], pos[2], pos[3], rot[1], rot[2], rot[3], growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, splitShapeFileId)
        end
        i = i + 1
    end
    delete(xmlFile)
    return true
end
function TreePlantManager:saveToXMLFile(xmlFilename)
    self:cleanupDeletedTrees()
    local xmlFile = createXMLFile("treePlantXML", xmlFilename, "treePlant")
    if xmlFile == 0 then
        Logging.error("Failed to create xml file %q", xmlFilename)
        return false
    end
    local index = 0
    for _, tree in ipairs(self.treesData.growingTrees) do
        (function(tree, xmlIndex)
            -- upvalues: (copy) self, (copy) xmlFile
            local treeTypeName = self:getTreeTypeDescFromIndex(tree.treeType).name
            local isGrowing = getChildAt(tree.node, 0) == tree.origSplitShape
            local treeKey = string.format("treePlant.tree(%d)", xmlIndex)
            setXMLString(xmlFile, treeKey .. "#treeType", treeTypeName)
            setXMLString(xmlFile, treeKey .. "#position", string.format("%.4f %.4f %.4f", tree.x, tree.y, tree.z))
            setXMLString(xmlFile, treeKey .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(tree.rx), math.deg(tree.ry), (math.deg(tree.rz))))
            setXMLInt(xmlFile, treeKey .. "#growthStateI", tree.growthStateI)
            if tree.variationIndex ~= 1 then
                setXMLInt(xmlFile, treeKey .. "#variationIndex", tree.variationIndex)
            end
            if tree.nextGrowthTargetHour ~= nil then
                setXMLFloat(xmlFile, treeKey .. "#nextGrowthTargetHour", tree.nextGrowthTargetHour)
            end
            setXMLBool(xmlFile, treeKey .. "#isGrowing", isGrowing)
            setXMLInt(xmlFile, treeKey .. "#splitShapeFileId", tree.splitShapeFileId or -1)
        end)(tree, index)
        index = index + 1
    end
    for _, tree in ipairs(self.treesData.splitTrees) do
        saveTreeToXML(tree, index)
        index = index + 1
    end
    saveXMLFile(xmlFile)
    delete(xmlFile)
    return true
end
function TreePlantManager:readFromServerStream(streamId)
    local numTrees = streamReadInt32(streamId)
    for i = 1, numTrees do
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
        local treeTypeDesc = self.indexToTreeType[treeType]
        if treeTypeDesc ~= nil then
            local nodeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, -1)
            setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
            self.treesData.clientTrees[serverSplitShapeFileId] = nodeId
        end
    end
end
function TreePlantManager:writeToClientStream(streamId)
    local treesData = self.treesData
    self:cleanupDeletedTrees()
    streamWriteInt32(streamId, #treesData.growingTrees + #treesData.splitTrees)
    for _, tree in ipairs(treesData.growingTrees) do
        streamWriteUInt8(streamId, tree.treeType)
        streamWriteFloat32(streamId, tree.x)
        streamWriteFloat32(streamId, tree.y)
        streamWriteFloat32(streamId, tree.z)
        streamWriteFloat32(streamId, tree.rx)
        streamWriteFloat32(streamId, tree.ry)
        streamWriteFloat32(streamId, tree.rz)
        streamWriteUIntN(streamId, tree.growthStateI, TreePlantManager.STAGE_NUM_BITS)
        streamWriteUIntN(streamId, tree.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
        streamWriteInt32(streamId, tree.splitShapeFileId)
    end
    for _, tree in ipairs(treesData.splitTrees) do
        streamWriteUInt8(streamId, tree.treeType)
        streamWriteFloat32(streamId, tree.x)
        streamWriteFloat32(streamId, tree.y)
        streamWriteFloat32(streamId, tree.z)
        streamWriteFloat32(streamId, tree.rx)
        streamWriteFloat32(streamId, tree.ry)
        streamWriteFloat32(streamId, tree.rz)
        streamWriteUIntN(streamId, tree.growthStateI, TreePlantManager.STAGE_NUM_BITS)
        streamWriteUIntN(streamId, tree.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
        streamWriteInt32(streamId, tree.splitShapeFileId)
    end
end
function TreePlantManager:getTreeTypeDescFromIndex(index)
    if self.treeTypes == nil then
        return nil
    else
        return self.treeTypes[index]
    end
end
function TreePlantManager:getTreeTypeNameFromIndex(index)
    if self.treeTypes == nil or self.treeTypes[index] == nil then
        return nil
    else
        return self.treeTypes[index].name
    end
end
function TreePlantManager:getTreeTypeDescFromName(name)
    if self.nameToTreeType == nil or name == nil then
        return nil
    end
    name = string.upper(name)
    return self.nameToTreeType[name]
end
function TreePlantManager:getTreeTypeIndexAndVariationFromName(name, stageIndex, variationName)
    if self.nameToTreeType ~= nil and name ~= nil then
        local treeTypeDesc = string.upper(name)
        local treeTypeDesc = self.nameToTreeType[treeTypeDesc]
        if treeTypeDesc ~= nil then
            local stage = treeTypeDesc.stages[stageIndex]
            if stage ~= nil then
                local variationIndex = nil
                for index, variation in ipairs(stage) do
                    if string.lower(variation.name or "DEFAULT") == string.lower(variationName or "DEFAULT") then
                        variationIndex = index
                        break
                    end
                end
                return treeTypeDesc.index, variationIndex
            end
        end
    end
    return nil, nil
end
function TreePlantManager:getTreeTypeNameAndVariationByIndex(treeTypeIndex, stageIndex, variationIndex)
    if self.treeTypes ~= nil then
        local treeTypeDesc = self.treeTypes[treeTypeIndex]
        if treeTypeDesc ~= nil then
            local variations = treeTypeDesc.stages[stageIndex or 1]
            if variations ~= nil then
                local variation = variations[variationIndex] or variations[1]
                if variation ~= nil then
                    return treeTypeDesc.name, variation.name or "DEFAULT"
                end
            end
        end
    end
    return nil, nil
end
function TreePlantManager:getPalletStoreItemFilenameByIndex(treeTypeIndex, stageIndex, variationIndex)
    if self.treeTypes ~= nil then
        local treeTypeDesc = self.treeTypes[treeTypeIndex]
        if treeTypeDesc ~= nil then
            local variations = treeTypeDesc.stages[stageIndex or 1]
            if variations ~= nil then
                local variation = variations[variationIndex] or variations[1]
                if variation ~= nil then
                    return variation.palletStoreItemFilename
                end
            end
        end
    end
    return nil
end
function TreePlantManager:getTreeTypeDescFromSplitType(splitTypeIndex)
    if self.splitTypeIndexToTreeType == nil or splitTypeIndex == nil then
        return nil
    else
        return self.splitTypeIndexToTreeType[splitTypeIndex]
    end
end
function TreePlantManager:getTreeTypeIndexFromName(name)
    if self.nameToTreeType ~= nil and name ~= nil then
        name = string.upper(name)
        if self.nameToTreeType[name] ~= nil then
            return self.nameToTreeType[name].index
        end
    end
    return nil
end
function TreePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
    if self.treesData ~= nil then
        self.treesData.clientTrees[serverSplitShapeFileId] = nodeId
    end
end
function TreePlantManager:removeClientTree(serverSplitShapeFileId)
    if self.treesData ~= nil then
        self.treesData.clientTrees[serverSplitShapeFileId] = nil
    end
end
function TreePlantManager:getClientTree(serverSplitShapeFileId)
    if self.treesData == nil then
        return nil
    else
        return self.treesData.clientTrees[serverSplitShapeFileId]
    end
end
function TreePlantManager:addingSplitShape(shape, oldShape, fromTree)
    local state, variation
    if oldShape == nil or self.activeDecayingSplitShapes[oldShape] == nil then
        if fromTree then
            state = 1
            local x, y, z = getWorldTranslation(shape)
            variation = math.abs(x) + math.abs(y) + math.abs(z)
        else
            state = 0
            variation = 80
        end
    else
        state = self.activeDecayingSplitShapes[oldShape].state
        variation = self.activeDecayingSplitShapes[oldShape].variation
    end
    if state ~= nil and getNumOfChildren(shape) > 0 then
        self.activeDecayingSplitShapes[shape] = {
            ["state"] = state,
            ["variation"] = variation
        }
        self:setSplitShapeLeafScaleAndVariation(shape, state, variation)
    end
    g_messageCenter:publish(MessageType.TREE_SHAPE_CUT, oldShape, shape)
end
function TreePlantManager:removingSplitShape(shape)
    self.activeDecayingSplitShapes[shape] = nil
end
function TreePlantManager:replaceWithTreeType(node, treeTypeIndex)
    local treeType = self:getTreeTypeDescFromIndex(treeTypeIndex)
    if treeType == nil then
        return nil
    end
    local x, y, z = getWorldTranslation(node)
    local rx, ry, rz = getWorldRotation(node)
    local newTreeNode = self:plantTree(treeType.index, x, y, z, rx, ry, rz, 1, 1, false)
    if newTreeNode ~= nil then
        delete(node)
    end
    return newTreeNode
end
function TreePlantManager.setSplitShapeLeafScaleAndVariation(_, shape, scale, variation)
    setShaderParameterRecursive(shape, "windSnowLeafScale", 0, 0, scale, variation, false)
end
function TreePlantManager:consoleCommandCutTrees(radius)
    radius = tonumber(radius) or 50
    self.commandCutTreeData = {}
    self.commandCutTreeData.trees = {}
    local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
    overlapSphere(x, y, z, radius, "onTreeCutCommandOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)
    return string.format("Found %d trees to cut in a %dm radius", #self.commandCutTreeData.trees, radius)
end
function TreePlantManager:onTreeCutCommandOverlapCallback(objectId, ...)
    if getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(objectId) ~= 0 and (getRigidBodyType(objectId) == RigidBodyType.STATIC and not getIsSplitShapeSplit(objectId))) then
        table.insert(self.commandCutTreeData.trees, objectId)
    end
end
function TreePlantManager:onTreeCutCommandSplitCallback(shape, _, _, _, _, _, _)
    rotate(shape, 0.1, 0, 0)
    g_currentMission:addKnownSplitShape(shape)
    self:addingSplitShape(shape, self.commandCutTreeData.shapeBeingCut, true)
end
function TreePlantManager:consoleCommandLoadTree(length, treeType, growthStage, delimb)
    local x, y, z = g_localPlayer:getPosition()
    local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
    local x = x + dirX * 4
    local z = z + dirZ * 4
    local y = y + 1
    if Platform.isMobile then
        local amount = tonumber(length)
        if amount == nil then
            return "No amount given. (gsTreeAdd amount)"
        end
        WoodHarvesterLight.spawnLogs("data/maps/trees/logs/pineLog.i3d", amount, x, y, z, MathUtil.getYRotationFromDirection(dirX, dirZ), 0.4, 5, self:getFarmId())
        return "Spawned log(s)"
    end
    local amount = tonumber(length)
    local amount = "gsTreeAdd length [type (available: " .. table.concatKeys(self.nameToTreeType, " ") .. ")] [growthStage] [delimb true/false]"
    if amount == nil then
        return "No length given. " .. amount
    end
    if treeType == nil then
        treeType = "beech"
        growthStage = 7
    end
    local treeTypeDesc = self:getTreeTypeDescFromName(treeType)
    if treeTypeDesc == nil then
        return "Invalid tree type. " .. amount
    end
    local variationIndex = tonumber(growthStage) or #treeTypeDesc.stages
    local variationIndex = math.clamp(variationIndex, 1, #treeTypeDesc.stages)
    self:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, 0, dirZ, amount, variationIndex, math.random(1, #treeTypeDesc.stages[variationIndex]), (Utils.stringToBoolean(delimb or "true")))
    return "Loaded tree"
end
function TreePlantManager:consoleCommandPlantTrees(treeTypeName, number, growthStateI, variationIndex, isGrowing)
    local treeType = self:getTreeTypeDescFromName(treeTypeName)
    if treeTypeName ~= nil and treeType == nil then
        printError(string.format("Error: unknown tree type %q", treeTypeName))
        print("Available types:\n" .. table.concatKeys(g_treePlantManager.nameToTreeType, ", "))
        return "Usage: gsTreePlant treeType number growthState variationIndex isGrowing"
    end
    local x = treeType or self:getTreeTypeDescFromName("lodgepolePine") or (self:getTreeTypeDescFromName("aspen") or self.treeTypes[1])
    number = tonumber(number) or 1
    local x = tonumber(growthStateI) or #x.stages
    local dirX = #x.stages
    local x = math.clamp(x, 1, dirX)
    local x = tonumber(variationIndex) or math.random(1, #x.stages[x])
    local dirX = #x.stages[x]
    local x = math.clamp(x, 1, dirX)
    local x = Utils.stringToBoolean(isGrowing)
    local x, y, z = g_localPlayer:getPosition()
    local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
    local x = x + dirX * 5
    local z = z + dirZ * 5
    local numPlantedTrees = 0
    local i = 0
    for i = i, number - 1 do
        local tx = x + dirX * i * 5
        local tz = z + dirZ * i * 5
        local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, y, tz)
        local ry = math.random() * 2 * 3.141592653589793
        self.plantTreeCommandHasCollision = false
        overlapBox(tx, ty, tz, 0, 0, 0, 0.5, 1, 0.5, "onTreeOverlapCheckCallback", self, CollisionFlag.TREE)
        if self.plantTreeCommandHasCollision then
            printWarning("Warning: skipped tree due to overlap with existing tree")
        elseif self:plantTree(x.index, tx, ty, tz, 0, ry, 0, x, x, x) then
        end
    end
    return string.format("Planted %d trees of type %s", numPlantedTrees, x.name)
end
function TreePlantManager:consoleCommandLoadAll(_, _, _, _, _)
    g_debugManager:removeGroup("treeLoadAll")
    local x, _, z = g_localPlayer:getPosition()
    local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
    local yRot = MathUtil.getYRotationFromDirection(-dirX, -dirZ)
    local x = x + dirX * 5
    local z = z + dirZ * 5
    local numPlantedTrees = 0
    for index, treeType in ipairs(self.treeTypes) do
        local tx = x + dirZ * index * 10
        local tz = z - dirX * index * 10
        for stageIndex, stage in ipairs(treeType.stages) do
            for variationIndex, variation in ipairs(stage) do
                local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, 0, tz)
                local treeId = self:plantTree(treeType.index, tx, ty, tz, 0, math.random() * 3.141592653589793, 0, stageIndex, variationIndex, false)
                if treeId ~= nil and treeId ~= 0 then
                    local splitShapeId = getChildAt(getChildAt(treeId, 0), 0)
                    local splitTypeIndex = -1
                    local splitTypeName = "<NO_SPLIT_TYPE>"
                    local allowWoodHarvester = false
                    local sizeX = nil
                    local sizeY = nil
                    local sizeZ = nil
                    local numConvexes = nil
                    local numAttachments = nil
                    if splitShapeId ~= 0 and getHasClassId(splitShapeId, ClassIds.MESH_SPLIT_SHAPE) then
                        splitTypeIndex = getSplitType(splitShapeId)
                        splitTypeName = g_splitShapeManager:getSplitTypeNameByIndex(splitTypeIndex)
                        allowWoodHarvester = g_splitShapeManager:getSplitShapeAllowsHarvester(splitShapeId)
                        sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(splitShapeId)
                        local boundingBox = getSplitShapeOrientedBoundingBox(splitShapeId)
                        local dir0X, dir0Y, dir0Z, dir1X, dir1Y, dir1Z, _, _, _, centerX, centerY, centerZ, extent0, extent1, extent2 = unpack(boundingBox)
                        local sx, sy, sz = localToWorld(splitShapeId, centerX, 0, centerZ)
                        local debugPlane, debugText, rCenterX = localDirectionToWorld(splitShapeId, dir1X, dir1Y, dir1Z)
                        local debugPlane, debugText, rCenterX = localDirectionToWorld(splitShapeId, dir0X, dir0Y, dir0Z)
                        local debugPlane = DebugPlane.new():createFromPosAndDir(sx, sy, sz, debugPlane, debugText, rCenterX, debugPlane, debugText, rCenterX, extent2 * 2, extent1 * 2)
                        debugPlane.color = allowWoodHarvester and Color.PRESETS.GREEN or Color.PRESETS.RED
                        g_debugManager:addElement(debugPlane, "treeLoadAll")
                        local debugText = DebugText3D.new():createWithWorldPos(sx - dirX * 0.75, sy + 0.1, sz - dirZ * 0.75, 0, yRot, 0, string.format("Area: %.1fm\194\178", sizeY * sizeZ), 0.07)
                        debugText.color = debugPlane.color
                        g_debugManager:addElement(debugText, "treeLoadAll")
                        local rCenterX, rCenterY, rCenterZ, _, _, _, radius = SplitShapeUtil.getTreeOffsetPosition(splitShapeId, tx, ty + 0.5, tz, 20, 0)
                        if rCenterX ~= nil then
                            local color = radius <= 0.601 and (radius <= 0.351 and Color.PRESETS.GREEN or Color.PRESETS.ORANGE) or Color.PRESETS.RED
                            local debugCircleRadius1 = DebugCircle.new():createWithWorldPos(rCenterX, rCenterY, rCenterZ, radius, color, 20, false, false, false, false)
                            g_debugManager:addElement(debugCircleRadius1, "treeLoadAll")
                            local debugTextRadius1 = DebugText3D.new():createWithWorldPos(rCenterX - dirX * radius * 1.2, rCenterY, rCenterZ - dirZ * radius * 1.2, 0, yRot, 0, string.format("Diameter: %.1fcm", radius * 200), 0.05)
                            debugTextRadius1.color = color
                            g_debugManager:addElement(debugTextRadius1, "treeLoadAll")
                        end
                        local color, debugCircleRadius1, debugTextRadius1, _, _, _, radius = SplitShapeUtil.getTreeOffsetPosition(splitShapeId, tx, ty + 1, tz, 20, 0)
                        if color ~= nil then
                            local color = radius <= 0.601 and (radius <= 0.351 and Color.PRESETS.GREEN or Color.PRESETS.ORANGE) or Color.PRESETS.RED
                            local debugCircleRadius1 = DebugCircle.new():createWithWorldPos(color, debugCircleRadius1, debugTextRadius1, radius, color, 20, false, false, false, false)
                            g_debugManager:addElement(debugCircleRadius1, "treeLoadAll")
                            local debugTextRadius1 = DebugText3D.new():createWithWorldPos(color - dirX * radius * 1.2, debugCircleRadius1, debugTextRadius1 - dirZ * radius * 1.2, 0, yRot, 0, string.format("Diameter: %.1fcm", radius * 200), 0.05)
                            debugTextRadius1.color = color
                            g_debugManager:addElement(debugTextRadius1, "treeLoadAll")
                        end
                    end
                    local boundingBox = ""
                    if sizeX ~= nil then
                        boundingBox = string.format("\nSplit Shape Size: Height: %.2f | Width: %.2f | Length: %.2f | Area: %.2f m\194\178 | convexes: %d | attachments: %d", sizeX, sizeY, sizeZ, sizeY * sizeZ, numConvexes, numAttachments)
                    end
                    local dir0X = DebugText3D.new()
                    local dir0Z = tx - dirX
                    local dir1X = ty + 0.5
                    local dir1Y = tz - dirZ
                    local dir1Z = 0
                    local _ = 0
                    local _ = string.format
                    local centerX = "%s : %s\nsplitType: %s / %s%s%s"
                    local centerY = treeType.name
                    local centerZ = Utils.getFilenameInfo(variation.filename, true)
                    local sx = allowWoodHarvester and "\n\nSupports Wood Harvester" or ""
                    local dir0X = dir0X:createWithWorldPos(dir0Z, dir1X, dir1Y, dir1Z, yRot, _, _(centerX, centerY, centerZ, splitTypeIndex, splitTypeName, boundingBox, sx), 0.07)
                    if allowWoodHarvester then
                        dir0X:setColor(Color.PRESETS.GREEN)
                    end
                    g_debugManager:addElement(dir0X, "treeLoadAll")
                    self:loadTreeTrunk(treeType, tx + dirZ * 2, ty, tz - dirX * 2, dirX, 0, dirZ, 0.25, stageIndex, variationIndex, true, true)
                    tx = tx + dirX * 10
                    tz = tz + dirZ * 10
                end
            end
        end
    end
    return string.format("Planted %d trees", numPlantedTrees)
end
function TreePlantManager:onTreeOverlapCheckCallback(objectId, ...)
    if getHasClassId(objectId, ClassIds.SHAPE) and getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) then
        self.plantTreeCommandHasCollision = true
    end
end
function TreePlantManager:consoleCommandRemoveSplitShape()
    local cam = getCamera()
    local wx, wy, wz = getWorldTranslation(cam)
    local dx, dy, dz = localDirectionToWorld(cam, 0, 0, -1)
    if raycastClosest(wx, wy, wz, dx, dy, dz, 10, "callback", {
        ["callback"] = function(_, shape, ...)
            if shape ~= 0 then
                local minX, maxX, _, _, minZ, maxZ = getRigidBodyAABB(shape)
                if getName(shape) == "LOD0" and getRigidBodyType(shape) == RigidBodyType.STATIC then
                    shape = getParent(shape)
                end
                Logging.info("removed %s (%d)", I3DUtil.getNodePath(shape), shape)
                delete(shape)
                g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
                g_currentMission.aiSystem:setAreaDirty(minX, minZ, maxX, maxZ)
            end
        end
    }, CollisionFlag.TREE) == 0 then
        printWarning("No split shape found at current camera ray")
    end
end
function TreePlantManager:consoleCommandDebug()
    self.debugActive = not self.debugActive
    if self.debugActive then
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
    end
    return "Tree/Splitshape debug = " .. tostring(self.debugActive)
end
g_treePlantManager = TreePlantManager.new()