AIDischargeable = {}
function AIDischargeable.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end
function AIDischargeable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Dischargeable")
    schema:register(XMLValueType.BOOL, "vehicle.dischargeable.dischargeNode(?)#allowAIDischarge", "Allows ai discharge", false)
    schema:register(XMLValueType.BOOL, "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?).dischargeNode(?)#allowAIDischarge", "Allows ai discharge", false)
    schema:register(XMLValueType.VECTOR_3, "vehicle.dischargeable.dischargeNode(?)#aiRootNodeCustomOffsets", "An additional custom offset between the ai root node and the discharge node", false)
    schema:register(XMLValueType.VECTOR_3, "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?).dischargeNode(?)#aiRootNodeCustomOffsets", "An additional custom offset between the ai root node and the discharge node", false)
    schema:setXMLSpecializationType()
end
function AIDischargeable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAIDischargeNodes", AIDischargeable.getAIDischargeNodes)
    SpecializationUtil.registerFunction(vehicleType, "getAIDischargeNodeZAlignedOffset", AIDischargeable.getAIDischargeNodeZAlignedOffset)
    SpecializationUtil.registerFunction(vehicleType, "getAICanStartDischarge", AIDischargeable.getAICanStartDischarge)
    SpecializationUtil.registerFunction(vehicleType, "startAIDischarge", AIDischargeable.startAIDischarge)
    SpecializationUtil.registerFunction(vehicleType, "stoppedAIDischarge", AIDischargeable.stoppedAIDischarge)
    SpecializationUtil.registerFunction(vehicleType, "finishedAIDischarge", AIDischargeable.finishedAIDischarge)
    SpecializationUtil.registerFunction(vehicleType, "getAIHasFinishedDischarge", AIDischargeable.getAIHasFinishedDischarge)
end
function AIDischargeable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", AIDischargeable.loadDischargeNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeAutomaticDischarge", AIDischargeable.getDischargeNodeAutomaticDischarge)
end
function AIDischargeable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AIDischargeable)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIDischargeable)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIDischargeable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIDischargeable)
    SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", AIDischargeable)
end
function AIDischargeable:onPreLoad()
    self.spec_aiDischargeable.aiDischargeNodes = {}
end
function AIDischargeable:onLoad()
    self.spec_aiDischargeable.currentDischargeNode = nil
end
function AIDischargeable:onPostLoad()
    local spec = self.spec_aiDischargeable
    if spec.aiDischargeNodes ~= nil then
        for _, dischargeNode in ipairs(spec.aiDischargeNodes) do
            dischargeNode.inputAttacherJointOffsets = {}
            if self.getInputAttacherJoints ~= nil then
                for _, inputAttacherJoint in ipairs(self:getInputAttacherJoints()) do
                    local x, y, z = localToLocal(dischargeNode.node, inputAttacherJoint.node, 0, 0, 0)
                    table.insert(dischargeNode.inputAttacherJointOffsets, { x, y, z })
                end
            end
            if self.getAIRootNode ~= nil then
                local aiRootNode = self:getAIRootNode()
                local offsetX = 0
                local offsetY = 0
                local _ = 0
                if dischargeNode.aiRootNodeCustomOffsets ~= nil then
                    offsetX = dischargeNode.aiRootNodeCustomOffsets[1]
                    offsetY = dischargeNode.aiRootNodeCustomOffsets[2]
                    _ = dischargeNode.aiRootNodeCustomOffsets[3]
                end
                dischargeNode.aiRootNodeOffsets = { localToLocal(dischargeNode.node, aiRootNode, offsetX, offsetY, _) }
            end
        end
    end
end
function AIDischargeable:onUpdate(_, _, _, _)
    local spec = self.spec_aiDischargeable
    if spec.currentDischargeNode ~= nil and (not spec.isAIDischargeRunning and self:getAIHasFinishedDischarge(spec.currentDischargeNode)) then
        self:finishedAIDischarge()
    end
end
function AIDischargeable:loadDischargeNode(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    entry.allowAIDischarge = xmlFile:getValue(key .. "#allowAIDischarge", false)
    entry.aiRootNodeCustomOffsets = xmlFile:getValue(key .. "#aiRootNodeCustomOffsets", nil, true)
    if entry.allowAIDischarge then
        local spec = self.spec_aiDischargeable
        local fillUnitAlreadyUsed = false
        for _, dischargeNode in ipairs(spec.aiDischargeNodes) do
            if dischargeNode.fillUnitIndex == entry.fillUnitIndex then
                fillUnitAlreadyUsed = true
                break
            end
        end
        if fillUnitAlreadyUsed then
            Logging.xmlWarning(xmlFile, "Discharge node fill unit index already used for AI. Discharge node will be ignored for \'%s\'", key)
        else
            table.insert(spec.aiDischargeNodes, entry)
        end
    end
    return true
end
function AIDischargeable:getDischargeNodeAutomaticDischarge(superFunc, dischargeNode)
    if Platform.gameplay.automaticDischarge and self:getIsAIActive() then
        return false
    else
        return superFunc(self, dischargeNode)
    end
end
function AIDischargeable:onDischargeStateChanged(state)
    local spec = self.spec_aiDischargeable
    if spec.currentDischargeNode ~= nil and (spec.isAIDischargeRunning and state == Dischargeable.DISCHARGE_STATE_OFF) then
        self:stoppedAIDischarge()
    end
end
function AIDischargeable:getAIDischargeNodes()
    return self.spec_aiDischargeable.aiDischargeNodes
end
function AIDischargeable:getAIDischargeNodeZAlignedOffset(dischargeNode, targetVehicle)
    if targetVehicle == self then
        return dischargeNode.aiRootNodeOffsets[1], dischargeNode.aiRootNodeOffsets[2], dischargeNode.aiRootNodeOffsets[3]
    end
    local index = self:getActiveInputAttacherJointDescIndex()
    local inputAttacherOffsets = dischargeNode.inputAttacherJointOffsets[index]
    local offsetX = inputAttacherOffsets[1]
    local offsetY = inputAttacherOffsets[2]
    local offsetZ = inputAttacherOffsets[3]
    local nextVehicle = self:getAttacherVehicle()
    while targetVehicle ~= nextVehicle do
        local attacherJoint = nextVehicle:getAttacherJointDescFromObject(self)
        local nextInputAttacherJointIndex = nextVehicle:getActiveInputAttacherJointDescIndex()
        local x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm = unpack(attacherJoint.inputAttacherJointOffsets[nextInputAttacherJointIndex])
        offsetZ = z + zNorm * offsetX + zUp * offsetY + zDir * offsetZ
        local nextVehicle = nextVehicle:getAttacherVehicle()
        offsetY = y + yNorm * offsetX + yUp * offsetY + yDir * offsetZ
        offsetX = x + xNorm * offsetX + xUp * offsetY + xDir * offsetZ
    end
    local nextInputAttacherJointIndex = targetVehicle:getAttacherJointDescFromObject(self).aiRootNodeOffset
    local offsets, x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm = unpack(nextInputAttacherJointIndex)
    return offsets + zUp * offsetX + zDir * offsetY + z * offsetZ, x + xNorm * offsetX + xUp * offsetY + xDir * offsetZ, y + yNorm * offsetX + yUp * offsetY + yDir * offsetZ
end
function AIDischargeable:getAICanStartDischarge(dischargeNode)
    return self:getCanDischargeToObject(dischargeNode)
end
function AIDischargeable:startAIDischarge(dischargeNode, task)
    local spec = self.spec_aiDischargeable
    spec.currentDischargeNode = dischargeNode
    spec.task = task
    spec.isAIDischargeRunning = true
    self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
end
function AIDischargeable:stoppedAIDischarge()
    self.spec_aiDischargeable.isAIDischargeRunning = false
end
function AIDischargeable:finishedAIDischarge()
    local spec = self.spec_aiDischargeable
    if spec.task ~= nil then
        spec.task:finishedDischarge()
    end
    spec.currentDischargeNode = nil
    spec.task = nil
end
function AIDischargeable:getAIHasFinishedDischarge(dischargeNode)
    return true
end