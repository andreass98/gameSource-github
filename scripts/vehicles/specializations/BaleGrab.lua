BaleGrab = {}
BaleGrab.CLOSE_TIMER = 250
function BaleGrab.prerequisitesPresent(specializations)
    return true
end
function BaleGrab.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BaleGrab")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab#minSizeRound", "Min. size of round bales (for shop display only)")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab#maxSizeRound", "Max. size of round bales (for shop display only)")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab#minSizeSquare", "Min. size of square bales (for shop display only)")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab#maxSizeSquare", "Max. size of square bales (for shop display only)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab#triggerNode", "Trigger node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab#rootNode", "Root node", "Main component")
    schema:register(XMLValueType.STRING, "vehicle.baleGrab#dynamicMountType", "Dynamic mount type", "TYPE_FIX_ATTACH")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab#forceAcceleration", "Force acceleration", 20)
    schema:register(XMLValueType.INT, "vehicle.baleGrab.grab(?)#componentJointIndex", "Component joint index of grab")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab.grab(?)#dampingFactor", "Factor that is applied to the component joint rot/trans damping as soon as a bale is mounted", 20)
    schema:register(XMLValueType.INT, "vehicle.baleGrab.grab(?)#rotationAxis", "Rotation axis of component joint to detect if the grab is rotating out of the limits (only rotation or translation axis can be used)")
    schema:register(XMLValueType.ANGLE, "vehicle.baleGrab.grab(?)#rotationThreshold", "Threshold to mount the bale if the component is this angle off the component joint rotation", 5)
    schema:register(XMLValueType.INT, "vehicle.baleGrab.grab(?)#translationAxis", "Translation axis of component joint to detect if the grab is translating out of the limits (only rotation or translation axis can be used)")
    schema:register(XMLValueType.FLOAT, "vehicle.baleGrab.grab(?)#translationThreshold", "Threshold to mount the bale if the component is this translation off the component joint translation", 0.05)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.baleGrab.grab(?).movingTool(?)#node", "Node of moving tool to block while limit is exceeded")
    schema:register(XMLValueType.INT, "vehicle.baleGrab.grab(?).movingTool(?)#closingDirection", "Direction to block the moving tool", 1)
    schema:setXMLSpecializationType()
    g_storeManager:addSpecType("baleGrabMaxSizeRound", "shopListAttributeIconBaleSizeRound", BaleGrab.loadSpecValueMaxSizeRound, BaleGrab.getSpecValueMaxSizeRound, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("baleGrabMaxSizeSquare", "shopListAttributeIconBaleSizeSquare", BaleGrab.loadSpecValueMaxSizeSquare, BaleGrab.getSpecValueMaxSizeSquare, StoreSpecies.VEHICLE)
end
function BaleGrab.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "baleGrabTriggerCallback", BaleGrab.baleGrabTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", BaleGrab.addDynamicMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", BaleGrab.removeDynamicMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleGrabClosed", BaleGrab.getIsBaleGrabClosed)
    SpecializationUtil.registerFunction(vehicleType, "mountBaleGrabObject", BaleGrab.mountBaleGrabObject)
    SpecializationUtil.registerFunction(vehicleType, "unmountBaleGrabObject", BaleGrab.unmountBaleGrabObject)
end
function BaleGrab.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMovingToolMoveValue", BaleGrab.getMovingToolMoveValue)
end
function BaleGrab.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleGrab)
end
function BaleGrab:onLoad(_)
    local spec = self.spec_baleGrab
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#jointType", "vehicle.baleGrab#dynamicMountType")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#grabRefComponentJointIndex1", "vehicle.baleGrab.grab#componentJointIndex")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#grabRefComponentJointIndex2", "vehicle.baleGrab.grab#componentJointIndex")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#rotDiffThreshold1", "vehicle.baleGrab.grab#rotationThreshold")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrab#rotDiffThreshold2", "vehicle.baleGrab.grab#rotationThreshold")
    if self.isServer then
        spec.rootNode = self.xmlFile:getValue("vehicle.baleGrab#rootNode", self.rootNode, self.components, self.i3dMappings)
        spec.triggerNode = self.xmlFile:getValue("vehicle.baleGrab#triggerNode", nil, self.components, self.i3dMappings)
        if spec.triggerNode ~= nil then
            if CollisionFlag.getHasMaskFlagSet(spec.triggerNode, CollisionFlag.DYNAMIC_OBJECT) then
                addTrigger(spec.triggerNode, "baleGrabTriggerCallback", self)
            else
                Logging.xmlWarning(self.xmlFile, "BaleGrab trigger has no \'TRIGGER_DYNAMIC_OBJECT\' collision bit set!")
            end
            spec.jointNode = createTransformGroup("balegrabJointNode")
            link(spec.rootNode, spec.jointNode)
            spec.forceAcceleration = self.xmlFile:getValue("vehicle.baleGrab#forceAcceleration", 20)
            local dynamicMountTypeString = self.xmlFile:getValue("vehicle.baleGrab#dynamicMountType", "TYPE_FIX_ATTACH")
            spec.dynamicMountType = DynamicMountUtil[dynamicMountTypeString] or DynamicMountUtil.TYPE_FIX_ATTACH
            spec.grabs = {}
            self.xmlFile:iterate("vehicle.baleGrab.grab", function(_, key)
                -- upvalues: (copy) self, (copy) spec
                local grab = {
                    ["componentJointIndex"] = self.xmlFile:getValue(key .. "#componentJointIndex")
                }
                if grab.componentJointIndex == nil then
                    Logging.xmlWarning(self.xmlFile, "Missing component joint in \'%s", key)
                else
                    grab.dampingFactor = self.xmlFile:getValue(key .. "#dampingFactor", 20)
                    grab.rotationAxis = self.xmlFile:getValue(key .. "#rotationAxis")
                    if grab.rotationAxis == nil then
                        grab.translationAxis = self.xmlFile:getValue(key .. "#translationAxis")
                        if grab.translationAxis == nil then
                            Logging.xmlWarning(self.xmlFile, "Missing rotation or translation axis in \'%s", key)
                        else
                            grab.translationThreshold = self.xmlFile:getValue(key .. "#translationThreshold", 0.05)
                        end
                    else
                        grab.rotationThreshold = self.xmlFile:getValue(key .. "#rotationThreshold", 5)
                    end
                    if grab.rotationAxis ~= nil or grab.translationAxis then
                        grab.componentJoint = self.componentJoints[grab.componentJointIndex]
                        if grab.componentJoint == nil then
                            Logging.xmlWarning(self.xmlFile, "Invalid component joint index %s in \'%s", grab.componentJointIndex, key)
                        else
                            grab.componentJointActor0 = grab.componentJoint.jointNode
                            grab.componentJointActor1 = grab.componentJoint.jointNodeActor1
                            if grab.componentJointActor0 == grab.componentJointActor1 then
                                grab.componentJointActor1 = createTransformGroup("componentJointActor1")
                                if self:getParentComponent(grab.componentJointActor0) == self.components[grab.componentJoint.componentIndices[1]].node then
                                    link(self.components[grab.componentJoint.componentIndices[2]].node, grab.componentJointActor1)
                                else
                                    link(self.components[grab.componentJoint.componentIndices[1]].node, grab.componentJointActor1)
                                end
                                setWorldTranslation(grab.componentJointActor1, getWorldTranslation(grab.componentJointActor0))
                                setWorldRotation(grab.componentJointActor1, getWorldRotation(grab.componentJointActor0))
                            end
                            grab.movingTools = {}
                            self.xmlFile:iterate(key .. ".movingTool", function(_, movingToolKey)
                                -- upvalues: (ref) self, (copy) grab
                                local movingToolData = {
                                    ["node"] = self.xmlFile:getValue(movingToolKey .. "#node", nil, self.components, self.i3dMappings)
                                }
                                if movingToolData.node ~= nil then
                                    movingToolData.closingDirection = self.xmlFile:getValue(movingToolKey .. "#closingDirection")
                                    table.insert(grab.movingTools, movingToolData)
                                end
                            end)
                            grab.lastValues = { 0, 0, 0 }
                            grab.isClosed = false
                            grab.closeTimer = 0
                            grab.jointChecksum = 0
                            table.insert(spec.grabs, grab)
                        end
                    end
                end
            end)
        end
        spec.lastAllGrabsClosed = false
        spec.dynamicMountedObjects = {}
        spec.pendingDynamicMountObjects = {}
    end
    if spec.triggerNode == nil then
        SpecializationUtil.removeEventListener(self, "onPostLoad", BaleGrab)
        SpecializationUtil.removeEventListener(self, "onDelete", BaleGrab)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", BaleGrab)
    end
end
function BaleGrab:onPostLoad(_)
    local spec = self.spec_baleGrab
    local i = 1
    for i = i, #spec.grabs do
        local grab = spec.grabs[i]
        local toolIndex = #grab.movingTools
        for toolIndex = toolIndex, 1, -1 do
            local movingToolData = grab.movingTools[toolIndex]
            movingToolData.movingTool = self:getMovingToolByNode(movingToolData.node)
            if movingToolData.movingTool == nil then
                table.remove(grab.movingTools, toolIndex)
            end
        end
    end
end
function BaleGrab:onDelete()
    local spec = self.spec_baleGrab
    if spec.pendingDynamicMountObjects ~= nil then
        for object, _ in pairs(spec.pendingDynamicMountObjects) do
            if object.removeDeleteListener ~= nil then
                object:removeDeleteListener(self, BaleGrab.onPendingObjectDelete)
            end
            if object.removeMountStateChangeListener ~= nil then
                object:removeMountStateChangeListener(self, BaleGrab.onPendingObjectMountStateChanged)
            end
        end
        table.clear(spec.pendingDynamicMountObjects)
    end
    if spec.dynamicMountedObjects ~= nil then
        for object, _ in pairs(spec.dynamicMountedObjects) do
            self:unmountBaleGrabObject(object)
        end
        table.clear(spec.dynamicMountedObjects)
    end
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
        spec.triggerNode = nil
    end
end
function BaleGrab:onUpdateTick(dt, _, _, _)
    if self.isServer then
        local spec = self.spec_baleGrab
        local allGrabsClosed = next(spec.pendingDynamicMountObjects) ~= nil
        local i = 1
        for i = i, #spec.grabs do
            local grab = spec.grabs[i]
            if self:getIsBaleGrabClosed(grab) then
                grab.closeTimer = math.max(grab.closeTimer - dt, 0)
            else
                grab.closeTimer = BaleGrab.CLOSE_TIMER
            end
            local x = grab.closeTimer == 0
            if x == grab.isClosed then
                if grab.closeTimer == BaleGrab.CLOSE_TIMER then
                    local x, y, z = getTranslation(grab.componentJointActor0)
                    local rx, ry, rz = getRotation(grab.componentJointActor0)
                    grab.jointChecksum = x + y + z + rx + ry + rz
                end
            else
                local x, y, z = getTranslation(grab.componentJointActor0)
                local rx, ry, rz = getRotation(grab.componentJointActor0)
                local jointChecksum = x + y + z + rx + ry + rz
                if grab.jointChecksum == jointChecksum then
                    if next(spec.pendingDynamicMountObjects) == nil or grab.closeTimer ~= 0 then
                        if next(spec.pendingDynamicMountObjects) == nil and grab.closeTimer == BaleGrab.CLOSE_TIMER then
                            grab.isClosed = grab.closeTimer == 0
                        end
                    else
                        grab.isClosed = grab.closeTimer == 0
                    end
                else
                    grab.jointChecksum = jointChecksum
                    grab.isClosed = grab.closeTimer == 0
                end
            end
            if not grab.isClosed then
                allGrabsClosed = false
            end
        end
        if allGrabsClosed ~= spec.lastAllGrabsClosed then
            spec.lastAllGrabsClosed = allGrabsClosed
            if allGrabsClosed then
                for grab, isClosed in pairs(spec.pendingDynamicMountObjects) do
                    if spec.dynamicMountedObjects[grab] == nil and grab.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
                        self:unmountBaleGrabObject(grab)
                        self:mountBaleGrabObject(grab)
                    end
                end
                local i = 1
                for i = i, #spec.grabs do
                    local y = 1
                    for y = y, 3 do
                        if spec.grabs[i].rotationAxis == nil then
                            setJointTranslationLimitSpring(grab.componentJoint.jointIndex, y - 1, grab.componentJoint.transLimitSpring[y], grab.componentJoint.transLimitDamping[y] * grab.dampingFactor)
                        else
                            setJointRotationLimitSpring(grab.componentJoint.jointIndex, y - 1, grab.componentJoint.rotLimitSpring[y], grab.componentJoint.rotLimitDamping[y] * grab.dampingFactor)
                        end
                    end
                end
                return
            end
            for grab, isClosed in pairs(spec.dynamicMountedObjects) do
                self:unmountBaleGrabObject(grab)
            end
            local i = 1
            for i = i, #spec.grabs do
                local y = 1
                for y = y, 3 do
                    if spec.grabs[i].rotationAxis == nil then
                        setJointTranslationLimitSpring(grab.componentJoint.jointIndex, y - 1, grab.componentJoint.transLimitSpring[y], grab.componentJoint.transLimitDamping[y])
                    else
                        setJointRotationLimitSpring(grab.componentJoint.jointIndex, y - 1, grab.componentJoint.rotLimitSpring[y], grab.componentJoint.rotLimitDamping[y])
                    end
                end
            end
        end
    end
end
function BaleGrab:getMovingToolMoveValue(superFunc, movingTool)
    local move = superFunc(self, movingTool)
    local spec = self.spec_baleGrab
    local i = 1
    for i = i, #spec.grabs do
        local grab = spec.grabs[i]
        local toolIndex = 1
        for toolIndex = toolIndex, #grab.movingTools do
            local movingToolData = grab.movingTools[toolIndex]
            if movingToolData.movingTool == movingTool then
                movingToolData.lastMoveValue = move
                if grab.closeTimer < BaleGrab.CLOSE_TIMER and (next(spec.pendingDynamicMountObjects) ~= nil and math.sign(move) == movingToolData.closingDirection) then
                    move = 0
                end
            end
        end
    end
    return move
end
function BaleGrab:addDynamicMountedObject(object)
    self.spec_baleGrab.dynamicMountedObjects[object] = object
end
function BaleGrab:removeDynamicMountedObject(object, isDeleting)
    local spec = self.spec_baleGrab
    if object.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
        object:unmountDynamic()
    end
    spec.dynamicMountedObjects[object] = nil
    if isDeleting then
        spec.pendingDynamicMountObjects[object] = nil
    end
end
function BaleGrab:onPendingObjectDelete(object)
    local spec = self.spec_baleGrab
    if spec.pendingDynamicMountObjects[object] ~= nil or spec.dynamicMountedObjects[object] ~= nil then
        self:removeDynamicMountedObject(object, true)
    end
end
function BaleGrab:onPendingObjectMountStateChanged(object, mountState, mountObject)
    if mountState ~= MountableObject.MOUNT_TYPE_NONE and mountObject ~= self then
        local spec = self.spec_baleGrab
        if spec.pendingDynamicMountObjects[object] ~= nil or spec.dynamicMountedObjects[object] ~= nil then
            self:removeDynamicMountedObject(object, true)
        end
    end
end
function BaleGrab:baleGrabTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if onEnter then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and (object ~= self and (object.getSupportsMountDynamic ~= nil and (object:getSupportsMountDynamic() and (object.addMountStateChangeListener ~= nil and (object.nodeId ~= nil or object.rootNode ~= 0))))) then
            self.spec_baleGrab.pendingDynamicMountObjects[object] = (self.spec_baleGrab.pendingDynamicMountObjects[object] or 0) + 1
            if spec.pendingDynamicMountObjects[object] == 1 then
                object:addDeleteListener(self, BaleGrab.onPendingObjectDelete)
                object:addMountStateChangeListener(self, BaleGrab.onPendingObjectMountStateChanged)
                return
            end
        end
    elseif onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and spec.pendingDynamicMountObjects[object] ~= nil then
            spec.pendingDynamicMountObjects[object] = spec.pendingDynamicMountObjects[object] - 1
            if spec.pendingDynamicMountObjects[object] <= 0 then
                self:removeDynamicMountedObject(object, true)
                object:removeDeleteListener(self, BaleGrab.onPendingObjectDelete)
                object:removeMountStateChangeListener(self, BaleGrab.onPendingObjectMountStateChanged)
            end
        end
    end
end
function BaleGrab:getIsBaleGrabClosed(grab)
    local toolIndex = 1
    for toolIndex = toolIndex, #grab.movingTools do
        local movingToolData = grab.movingTools[toolIndex]
        local state = Cylindered.getMovingToolState(self, movingToolData.movingTool)
        if movingToolData.closingDirection > 0 then
            if state < 0.01 then
                return false
            end
        elseif state > 0.99 then
            return false
        end
    end
    if grab.rotationAxis == nil then
        if grab.translationAxis ~= nil then
            grab.lastValues[1], grab.lastValues[2], grab.lastValues[3] = localToLocal(grab.componentJointActor1, grab.componentJointActor0, 0, 0, 0)
            if grab.translationThreshold > 0 then
                if grab.lastValues[grab.translationAxis] > grab.translationThreshold then
                    return true
                end
            elseif grab.lastValues[grab.translationAxis] < grab.translationThreshold then
                return true
            end
        end
    else
        grab.lastValues[1], grab.lastValues[2], grab.lastValues[3] = localRotationToLocal(grab.componentJointActor1, grab.componentJointActor0, 0, 0, 0)
        if grab.rotationThreshold > 0 then
            if grab.lastValues[grab.rotationAxis] > grab.rotationThreshold then
                return true
            end
        elseif grab.lastValues[grab.rotationAxis] < grab.rotationThreshold then
            return true
        end
    end
    return false
end
function BaleGrab:mountBaleGrabObject(object)
    local spec = self.spec_baleGrab
    local rootNode = object.nodeId or object.rootNode
    local x, y, z = localToWorld(rootNode, getCenterOfMass(rootNode))
    setWorldTranslation(spec.jointNode, x, y, z)
    if not object:mountDynamic(self, spec.rootNode, spec.jointNode, spec.dynamicMountType, spec.forceAcceleration) then
        return false
    end
    local i = 1
    for i = i, 3 do
        setJointRotationLimitSpring(object.dynamicMountJointIndex, i - 1, 10000, 10)
        setJointTranslationLimitSpring(object.dynamicMountJointIndex, i - 1, 10000, 10)
    end
    self:addDynamicMountedObject(object)
    return true
end
function BaleGrab:unmountBaleGrabObject(object)
    self:removeDynamicMountedObject(object, false)
    return true
end
function BaleGrab:updateDebugValues(values)
    if self.isServer then
        local spec = self.spec_baleGrab
        local i = 1
        for i = i, #spec.grabs do
            local grab = spec.grabs[i]
            if grab.rotationAxis == nil then
                if grab.translationAxis ~= nil then
                    local isClosed = false
                    local lastMovingDirection, directionStr, blockStr = localToLocal(grab.componentJointActor1, grab.componentJointActor0, 0, 0, 0)
                    grab.lastValues[1] = lastMovingDirection
                    grab.lastValues[2] = directionStr
                    grab.lastValues[3] = blockStr
                    local isClosed
                    if grab.translationThreshold > 0 then
                    end
                    ({
                        ["name"] = string.format("grab (trans - %s):", getName(grab.componentJointActor0))
                    }).value = string.format("offset: %.3f / %.3f | state: %s (t %d)", grab.lastValues[grab.translationAxis], grab.translationThreshold, isClosed and "closed" or "open", grab.closeTimer)
                    table.insert(values, movingToolData)
                end
            else
                local isClosed = false
                local lastMovingDirection, directionStr, blockStr = localRotationToLocal(grab.componentJointActor1, grab.componentJointActor0, 0, 0, 0)
                grab.lastValues[1] = lastMovingDirection
                grab.lastValues[2] = directionStr
                grab.lastValues[3] = blockStr
                local isClosed
                if grab.rotationThreshold > 0 then
                end
                local blockStr = math.deg(grab.lastValues[grab.rotationAxis]);
                ({
                    ["name"] = string.format("grab (rot - %s):", getName(grab.componentJointActor0))
                }).value = string.format("offset: %.1fdeg / %.1fdeg | state: %s (t %d)", blockStr, math.deg(grab.rotationThreshold), isClosed and "closed" or "open", grab.closeTimer)
                table.insert(values, movingToolData)
            end
            local toolIndex = 1
            local isClosed = #grab.movingTools
            local rootNode = 1
            for toolIndex = toolIndex, isClosed, rootNode do
                local movingToolData = grab.movingTools[toolIndex]
                local lastMovingDirection = math.sign(movingToolData.lastMoveValue)
                local blockStr = lastMovingDirection == movingToolData.closingDirection and (grab.closeTimer < BaleGrab.CLOSE_TIMER and next(spec.pendingDynamicMountObjects) ~= nil) and " BLOCKED" or ""
                table.insert(values, {
                    ["name"] = "movingTool:",
                    ["value"] = string.format("%s | direction: %s%s", getName(movingToolData.movingTool.node), lastMovingDirection == movingToolData.closingDirection and "closing" or (lastMovingDirection == 0 and "none" or "opening"), blockStr)
                })
            end
        end
        table.insert(values, {
            ["name"] = "--",
            ["value"] = "--"
        })
        for grab, isClosed in pairs(spec.pendingDynamicMountObjects) do
            local rootNode = grab.nodeId or grab.rootNode
            local directionStr = {
                ["name"] = spec.dynamicMountedObjects[grab] == nil and "<> Pending    " or ">< Mounted    ",
                ["value"] = string.format("%s (id %d, numShapes %d)", getName(rootNode), rootNode, isClosed)
            }
            table.insert(values, directionStr)
        end
    end
end
function BaleGrab.loadSpecValueMaxSize(xmlFile, minKey, maxKey)
    local sizeData = {
        ["minSize"] = MathUtil.round(xmlFile:getValue(minKey) or 0, 2),
        ["maxSize"] = MathUtil.round(xmlFile:getValue(maxKey) or 0, 2)
    }
    if sizeData.minSize ~= 0 or sizeData.maxSize ~= 0 then
        return sizeData
    end
end
function BaleGrab.loadSpecValueMaxSizeRound(xmlFile, _, _)
    return BaleGrab.loadSpecValueMaxSize(xmlFile, "vehicle.baleGrab#minSizeRound", "vehicle.baleGrab#maxSizeRound")
end
function BaleGrab.loadSpecValueMaxSizeSquare(xmlFile, _, _)
    return BaleGrab.loadSpecValueMaxSize(xmlFile, "vehicle.baleGrab#minSizeSquare", "vehicle.baleGrab#maxSizeSquare")
end
function BaleGrab.getSpecValueMaxSize(specName, storeItem, _, _, _, returnValues, returnRange)
    local spec = storeItem.specs[specName]
    if spec == nil then
        return
    elseif returnValues == nil or not returnValues then
        local unit = g_i18n:getText("unit_cmShort")
        if (spec.maxSize or spec.minSize) == (spec.minSize or spec.maxSize) or ((spec.minSize or spec.maxSize) == 0 or (spec.maxSize or spec.minSize) == 0) then
            return string.format("%d%s", math.max(minValue, maxValue) * 100, unit)
        else
            return string.format("%d%s-%d%s", minValue * 100, unit, maxValue * 100, unit)
        end
    elseif returnRange == true and (maxValue ~= minValue and (minValue ~= 0 and maxValue ~= 0)) then
        return minValue * 100, maxValue * 100, g_i18n:getText("unit_cmShort")
    else
        return math.max(minValue, maxValue) * 100, g_i18n:getText("unit_cmShort")
    end
end
function BaleGrab.getSpecValueMaxSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    return BaleGrab.getSpecValueMaxSize("baleGrabMaxSizeRound", storeItem, realItem, configurations, saleItem, returnValues, returnRange)
end
function BaleGrab.getSpecValueMaxSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    return BaleGrab.getSpecValueMaxSize("baleGrabMaxSizeSquare", storeItem, realItem, configurations, saleItem, returnValues, returnRange)
end