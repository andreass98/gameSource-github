IKUtil = {}
function IKUtil.loadIKChain(xmlFile, key, targetBasenode, chainBasenode, ikTable)
    local ikChain = {
        ["id"] = getXMLString(xmlFile, key .. "#id"),
        ["target"] = I3DUtil.indexToObject(targetBasenode, getXMLString(xmlFile, key .. "#target")),
        ["targetOffset"] = string.getVector(getXMLString(xmlFile, key .. "#targetOffset"), 3)
    }
    if ikChain.targetOffset == nil then
        ikChain.targetOffset = { 0, 0, 0 }
    end
    ikChain.targetRotationOffset = string.getVector(getXMLString(xmlFile, key .. "#targetRotationOffset"), 3)
    if ikChain.targetRotationOffset == nil then
        ikChain.targetRotationOffset = { 0, 0, 0 }
    else
        ikChain.targetRotationOffset[1] = math.rad(ikChain.targetRotationOffset[1])
        ikChain.targetRotationOffset[2] = math.rad(ikChain.targetRotationOffset[2])
        ikChain.targetRotationOffset[3] = math.rad(ikChain.targetRotationOffset[3])
    end
    ikChain.alignToTarget = Utils.getNoNil(getXMLBool(xmlFile, key .. "#alignToTarget"), false)
    local numNodeElements = getXMLNumOfElements(xmlFile, key .. ".node")
    ikChain.nodes = table.create(numNodeElements)
    local j = 1
    for j = j, numNodeElements do
        local nodeKey = key .. string.format(".node(%d)", j - 1)
        local node = I3DUtil.indexToObject(chainBasenode, getXMLString(xmlFile, nodeKey .. "#index"))
        if node ~= nil then
            local maxRx = getXMLFloat(xmlFile, nodeKey .. "#minRx") or -180
            local minRx = math.rad(maxRx)
            local minRy = getXMLFloat(xmlFile, nodeKey .. "#maxRx") or 180
            local maxRx = math.rad(minRy)
            local maxRy = getXMLFloat(xmlFile, nodeKey .. "#minRy") or -180
            local minRy = math.rad(maxRy)
            local minRz = getXMLFloat(xmlFile, nodeKey .. "#maxRy") or 180
            local maxRy = math.rad(minRz)
            local maxRz = getXMLFloat(xmlFile, nodeKey .. "#minRz") or -180
            local minRz = math.rad(maxRz)
            local damping = getXMLFloat(xmlFile, nodeKey .. "#maxRz") or 180
            local maxRz = math.rad(damping)
            local localLimits = getXMLFloat(xmlFile, nodeKey .. "#damping") or 30
            local damping = math.rad(localLimits)
            local localLimits = Utils.getNoNil(getXMLBool(xmlFile, nodeKey .. "#localLimits"), false)
            local initTranslation = j == numNodeElements and { getTranslation(node) } or nil
            table.insert(ikChain.nodes, {
                ["node"] = node,
                ["minRx"] = minRx,
                ["maxRx"] = maxRx,
                ["minRy"] = minRy,
                ["maxRy"] = maxRy,
                ["minRz"] = minRz,
                ["maxRz"] = maxRz,
                ["damping"] = damping,
                ["localLimits"] = localLimits,
                ["initTranslation"] = initTranslation
            })
        end
    end
    ikChain.rotationNodes = IKUtil.loadRotationNodes(xmlFile, key, chainBasenode, true)
    local numPoseElements = getXMLNumOfElements(xmlFile, key .. ".pose")
    if numPoseElements > 0 then
        ikChain.poses = {}
        local nodeKey = 0
        for nodeKey = nodeKey, numPoseElements - 1 do
            local node = key .. string.format(".pose(%d)", nodeKey)
            local minRx = getXMLString(xmlFile, node .. "#id")
            if minRx ~= nil then
                local maxRx = {
                    ["id"] = minRx,
                    ["isDefaultPose"] = Utils.getNoNil(getXMLBool(xmlFile, node .. "#isDefaultPose"), false)
                }
                maxRx.rotationNodes = IKUtil.loadRotationNodes(xmlFile, node, chainBasenode, maxRx.isDefaultPose)
                ikChain.poses[minRx] = maxRx
            end
        end
    end
    if #ikChain.nodes <= 0 or (ikChain.target == nil or (ikChain.id == nil or ikTable[ikChain.id] ~= nil)) then
        return nil
    end
    ikChain.numIterations = getXMLInt(xmlFile, key .. "#numIterations") or 20
    ikChain.numIterationsToApply = getXMLInt(xmlFile, key .. "#numIterationsInit") or ikChain.numIterations * 2
    ikChain.positionThreshold = getXMLFloat(xmlFile, key .. "#positionThreshold") or 0.005
    ikChain.isDirty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isDirtyOnLoad"), false)
    ikChain.ikChainSolver = IKChain.new(#ikChain.nodes)
    for node, minRx in ipairs(ikChain.nodes) do
        ikChain.ikChainSolver:setJointTransformGroup(node - 1, minRx.node, minRx.minRx, minRx.maxRx, minRx.minRy, minRx.maxRy, minRx.minRz, minRx.maxRz, minRx.damping, minRx.localLimits)
    end
    ikChain.isActive = true
    ikTable[ikChain.id] = ikChain
    return ikChain
end
function IKUtil.loadRotationNodes(xmlFile, key, chainBasenode, apply)
    local numRotatioNodes = getXMLNumOfElements(xmlFile, key .. ".rotationNode")
    if numRotatioNodes == 0 then
        return nil
    end
    local rotationNodes = {}
    local i = 0
    for i = i, numRotatioNodes - 1 do
        local nodeKey = key .. string.format(".rotationNode(%d)", i)
        local node = I3DUtil.indexToObject(chainBasenode, getXMLString(xmlFile, nodeKey .. "#index"))
        if node ~= nil then
            local rotConfig = string.getRadians(getXMLString(xmlFile, nodeKey .. "#rotation"), 3)
            local rot = rotConfig or { getRotation(node) }
            if apply and rotConfig ~= nil then
                setRotation(node, unpack(rotConfig))
            end
            table.insert(rotationNodes, {
                ["node"] = node,
                ["defaultRotation"] = rot
            })
        end
    end
    return rotationNodes
end
function IKUtil.setRotationNodes(rotationNodes)
    for _, rotationNode in pairs(rotationNodes) do
        setRotation(rotationNode.node, unpack(rotationNode.defaultRotation))
    end
end
function IKUtil.deleteIKChain(ikTable, id)
    local ikChain = ikTable[id]
    if ikChain ~= nil then
        ikChain.ikChainSolver = nil
    end
    ikTable[id] = nil
end
function IKUtil.setTarget(ikTable, id, target)
    local ikChain = ikTable[id]
    if ikChain ~= nil then
        if target == nil then
            if ikChain.defaultTarget ~= nil then
                ikChain.target = ikChain.defaultTarget
                if ikChain.rotationNodes ~= nil then
                    IKUtil.setRotationNodes(ikChain.rotationNodes)
                end
            end
            if ikChain.offsetTargetNode ~= nil then
                delete(ikChain.offsetTargetNode)
                ikChain.offsetTargetNode = nil
            end
        else
            if ikChain.defaultTarget == nil then
                ikChain.defaultTarget = ikChain.target
            end
            ikChain.offsetTargetNode = createTransformGroup("ikOffsetTargetNode")
            link(target.targetNode, ikChain.offsetTargetNode)
            if ikChain.targetRotationOffset ~= nil then
                setRotation(ikChain.offsetTargetNode, ikChain.targetRotationOffset[1], ikChain.targetRotationOffset[2], ikChain.targetRotationOffset[3])
            end
            if ikChain.targetOffset ~= nil then
                local x, y, z = localToLocal(ikChain.offsetTargetNode, getParent(ikChain.offsetTargetNode), ikChain.targetOffset[1], ikChain.targetOffset[2], ikChain.targetOffset[3])
                setTranslation(ikChain.offsetTargetNode, x, y, z)
            end
            ikChain.target = ikChain.offsetTargetNode
            ikChain.actualTargetNode = target.targetNode
            if target.rotationNodes ~= nil and ikChain.rotationNodes ~= nil then
                for _, rotationNode in pairs(target.rotationNodes) do
                    local rotNode = ikChain.rotationNodes[rotationNode.id]
                    if rotNode ~= nil then
                        setRotation(rotNode.node, unpack(rotationNode.rotation))
                    end
                end
            end
            if target.poseId ~= nil then
                IKUtil.setIKChainPose(ikTable, id, target.poseId)
                return
            end
        end
    end
end
function IKUtil.updateIKChains(ikChains, translateAlignNodes)
    for _, ikChain in pairs(ikChains) do
        if ikChain.isDirty and ikChain.isActive then
            ikChain.isDirty = false
            IKUtil.updateIKChain(ikChain, ikChain.numIterationsToApply, ikChain.positionThreshold, translateAlignNodes)
            ikChain.numIterationsToApply = ikChain.numIterations
        end
    end
    if VehicleDebug ~= nil and VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
        IKUtil.debugDrawChains(ikChains, true)
    end
end
function IKUtil.debugDrawChains(ikChains, drawLimits)
    for _, ikChain in pairs(ikChains) do
        if ikChain.isActive then
            IKUtil.debugDrawChain(ikChain, drawLimits)
        end
    end
end
function IKUtil.debugDrawChain(ikChain, drawLimits)
    ikChain.ikChainSolver:debugDraw(drawLimits == nil and true or drawLimits)
    local x1, y1, z1 = getWorldTranslation(ikChain.nodes[1].node)
    local x2, y2, z2 = getWorldTranslation(ikChain.target)
    drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0)
    DebugGizmo.renderAtNode(ikChain.target, getName(ikChain.target), false, 0.1, false)
    local x, y, z = localToWorld(ikChain.target, 0, 0, 0)
    local dx, dy, dz = localDirectionToWorld(ikChain.target, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(ikChain.target, 0, 1, 0)
    DebugGizmo.renderAtPosition(x, y, z, dx, dy, dz, upX, upY, upZ, "", false, 0.1, nil, Color.PRESETS.RED)
end
function IKUtil.updateIKChain(ikChain, numIterations, positionThreshold, translateAlignNode)
    local x, y, z = getWorldTranslation(ikChain.target)
    if ikChain.alignToTarget then
        local alignNodeData = ikChain.nodes[#ikChain.nodes]
        setTranslation(alignNodeData.node, unpack(alignNodeData.initTranslation))
    end
    ikChain.ikChainSolver:solve(x, y, z, numIterations, positionThreshold)
    if ikChain.alignToTarget and ikChain.isActive then
        local alignNodeData = ikChain.nodes[#ikChain.nodes].node
        if translateAlignNode then
            setWorldTranslation(alignNodeData, getWorldTranslation(ikChain.target))
        end
        setWorldRotation(alignNodeData, getWorldRotation(ikChain.target))
    end
end
function IKUtil.setIKChainDirty(ikTable, id)
    local ikChain = ikTable[id]
    if ikChain ~= nil then
        ikChain.isDirty = true
    end
end
function IKUtil.setIKChainActive(ikTable, id)
    local ikChain = ikTable[id]
    if ikChain ~= nil then
        ikChain.isActive = true
    end
end
function IKUtil.setIKChainInactive(ikTable, id)
    local ikChain = ikTable[id]
    if ikChain ~= nil then
        ikChain.isActive = false
    end
end
function IKUtil.setIKChainPose(ikTable, chainId, poseId)
    local ikChain = ikTable[chainId]
    if ikChain ~= nil and ikChain.poses ~= nil then
        local pose = ikChain.poses[poseId]
        if pose ~= nil and pose.rotationNodes ~= nil then
            IKUtil.setRotationNodes(pose.rotationNodes)
        end
    end
end
function IKUtil.getIKChainByTarget(ikTable, targetNode)
    for _, ikChain in pairs(ikTable) do
        if ikChain.actualTargetNode == targetNode then
            return ikChain
        end
    end
    return nil
end
function IKUtil.loadIKChainTargets(xmlFile, baseName, rootNode, targets, i3dMappings)
    local i = 0
    while true do
        local key = string.format(baseName .. ".target(%d)", i)
        if not xmlFile:hasProperty(key) then
            break
        end
        local ikName = xmlFile:getValue(key .. "#ikChain")
        local targetNode = xmlFile:getValue(key .. "#targetNode", nil, rootNode, i3dMappings)
        if targetNode == nil then
            Logging.xmlWarning(xmlFile, "Missing targetNode in \'%s\' for chain \'%s\'", key, ikName)
        elseif ikName == nil then
            Logging.xmlWarning(xmlFile, "Missing ikName for target \'%s\'", key)
        else
            local target = {
                ["ikName"] = ikName,
                ["targetNode"] = targetNode,
                ["targetOffset"] = xmlFile:getValue(key .. "#targetOffset", nil, true),
                ["setDirty"] = xmlFile:getValue(key .. "#setDirty", true)
            }
            local numRotatioNodes = xmlFile:getNumOfElements(key .. ".rotationNode")
            if numRotatioNodes > 0 then
                target.rotationNodes = {}
                local j = 0
                for j = j, numRotatioNodes - 1 do
                    local nodeKey = key .. string.format(".rotationNode(%d)", j)
                    local id = xmlFile:getValue(nodeKey .. "#id")
                    if id ~= nil then
                        local rotation = xmlFile:getValue(nodeKey .. "#rotation", "0 0 0", true)
                        table.insert(target.rotationNodes, {
                            ["id"] = id,
                            ["rotation"] = rotation
                        })
                    end
                end
            end
            target.poseId = xmlFile:getValue(key .. "#poseId")
            targets[target.ikName] = target
        end
        i = i + 1
    end
end
function IKUtil.registerIKChainTargetsXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".target(?)#ikChain", "IK chain name")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".target(?)#targetNode", "Target node")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".target(?)#targetOffset", "Target translation offset")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".target(?)#targetRotationOffset", "Target rotation offset")
    schema:register(XMLValueType.BOOL, basePath .. ".target(?)#setDirty", "Is dirty", true)
    schema:register(XMLValueType.INT, basePath .. ".target(?).rotationNode(?)#id", "Rotation node index")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".target(?).rotationNode(?)#rotation", "Rotation node rotation")
    schema:register(XMLValueType.STRING, basePath .. ".target(?)#poseId", "Pose id")
end
function IKUtil.registerIKChainXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#id", "Chain identifier")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#target", "Target node")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#targetOffset", "Target translation offset", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#targetRotationOffset", "Target rotation offset", "0 0 0")
    schema:register(XMLValueType.BOOL, basePath .. "#alignToTarget", "Align to target", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#index", "Chain node")
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRx", "Min. rotation X", -180)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRx", "Max. rotation X", 180)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRy", "Min. rotation Y", -180)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRy", "Max. rotation Y", 180)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRz", "Min. rotation Z", -180)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRz", "Max. rotation Z", 180)
    schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#damping", "Damping", 30)
    schema:register(XMLValueType.BOOL, basePath .. ".node(?)#localLimits", "Local limits", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rotationNode(?)#index", "Rotation node")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".rotationNode(?)#rotation", "Rotation")
    schema:register(XMLValueType.STRING, basePath .. ".pose(?)#id", "Pose id")
    schema:register(XMLValueType.BOOL, basePath .. ".pose(?)#isDefaultPose", "Is default pose", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".pose(?).rotationNode(?)#index", "Rotation node")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pose(?).rotationNode(?)#rotation", "Rotation")
    schema:register(XMLValueType.INT, basePath .. "#numIterations", "Max. number of iterations", 20)
    schema:register(XMLValueType.INT, basePath .. "#numIterationsInit", "Initial max. number of iterations", "numIterations * 2")
    schema:register(XMLValueType.FLOAT, basePath .. "#positionThreshold", "Position threshold", 0.005)
    schema:register(XMLValueType.BOOL, basePath .. "#isDirtyOnLoad", "Is dirty on load", false)
end