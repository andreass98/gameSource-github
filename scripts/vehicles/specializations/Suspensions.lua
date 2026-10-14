Suspensions = {}
Suspensions.DEFAULT_MAX_UPDATE_DISTANCE = 40
Suspensions.SUSPENSION_NODE_XML_KEY = "vehicle.suspensions.suspension(?)"
function Suspensions.prerequisitesPresent(specializations)
    return true
end
function Suspensions.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Suspensions")
    local key = Suspensions.SUSPENSION_NODE_XML_KEY
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Suspension node")
    schema:register(XMLValueType.BOOL, key .. "#useCharacterTorso", "Use character torso instead of node")
    schema:register(XMLValueType.FLOAT, key .. "#weight", "Weight in kg", 500)
    schema:register(XMLValueType.VECTOR_ROT, key .. "#minRotation", "Min. rotation")
    schema:register(XMLValueType.VECTOR_ROT, key .. "#maxRotation", "Max. rotation")
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#startTranslationOffset", "Custom translation offset")
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#minTranslation", "Min. translation")
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#maxTranslation", "Max. translation")
    schema:register(XMLValueType.FLOAT, key .. "#maxVelocityDifference", "Max. velocity difference", 0.1)
    schema:register(XMLValueType.VECTOR_2, key .. "#suspensionParametersX", "Suspension parameters X", "0 0")
    schema:register(XMLValueType.VECTOR_2, key .. "#suspensionParametersY", "Suspension parameters Y", "0 0")
    schema:register(XMLValueType.VECTOR_2, key .. "#suspensionParametersZ", "Suspension parameters Z", "0 0")
    schema:register(XMLValueType.BOOL, key .. "#inverseMovement", "Invert movement", false)
    schema:register(XMLValueType.BOOL, key .. "#serverOnly", "Suspension is only calculated on server side", false)
    schema:register(XMLValueType.FLOAT, "vehicle.suspensions#maxUpdateDistance", "Max. distance to vehicle root to update suspension nodes", Suspensions.DEFAULT_MAX_UPDATE_DISTANCE)
    schema:setXMLSpecializationType()
end
function Suspensions.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadSuspensionNodeFromXML", Suspensions.loadSuspensionNodeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getSuspensionNodeFromIndex", Suspensions.getSuspensionNodeFromIndex)
    SpecializationUtil.registerFunction(vehicleType, "getIsSuspensionNodeActive", Suspensions.getIsSuspensionNodeActive)
    SpecializationUtil.registerFunction(vehicleType, "setSuspensionNodeCharacter", Suspensions.setSuspensionNodeCharacter)
end
function Suspensions.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Suspensions)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Suspensions)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Suspensions)
    SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", Suspensions)
end
function Suspensions:onLoad(_)
    if self.isClient then
        local spec = self.spec_suspensions
        spec.suspensionNodes = {}
        for _, key in self.xmlFile:iterator("vehicle.suspensions.suspension") do
            local suspensionNode = {}
            if self:loadSuspensionNodeFromXML(self.xmlFile, key, suspensionNode) and (not suspensionNode.serverOnly or self.isServer) then
                table.insert(spec.suspensionNodes, suspensionNode)
            end
        end
        spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.suspensions#maxUpdateDistance", Suspensions.DEFAULT_MAX_UPDATE_DISTANCE)
        if #spec.suspensionNodes > 0 then
            spec.suspensionAvailable = true
        end
        if not Platform.gameplay.allowSuspensionNodes and self.xmlFile:hasProperty("vehicle.suspensions") then
            Logging.xmlWarning(self.xmlFile, "Suspension nodes are not allowed on this platform")
            spec.suspensionAvailable = false
            spec.suspensionNodes = {}
        end
    end
    if not self.spec_suspensions.suspensionAvailable then
        SpecializationUtil.removeEventListener(self, "onUpdate", Suspensions)
        SpecializationUtil.removeEventListener(self, "onEnterVehicle", Suspensions)
        SpecializationUtil.removeEventListener(self, "onVehicleCharacterChanged", Suspensions)
    end
end
function Suspensions:onUpdate(dt, _, _, _)
    local spec = self.spec_suspensions
    if self.currentUpdateDistance < spec.maxUpdateDistance then
        local timeDelta
        if self.isServer then
            timeDelta = 0.001 * g_physicsDt
        else
            timeDelta = 0.001 * dt
        end
        for _, suspension in ipairs(spec.suspensionNodes) do
            if suspension.node == nil or not entityExists(suspension.node) then
                if suspension.node ~= nil then
                    Logging.xmlError(self.xmlFile, "Failed to update suspension node %d. Node does not exist anymore!", suspension.node)
                    suspension.node = nil
                end
            else
                local wx = suspension.curAcc
                local wy = suspension.curAcc
                local wz = suspension.curAcc
                wx[1] = 0
                wy[2] = 0
                wz[3] = 0
                if self:getIsSuspensionNodeActive(suspension) then
                    local wx = localToWorld
                    local wy = suspension.component
                    local wx, wy, wz = wx(wy, unpack(suspension.refNodeOffset))
                    if suspension.lastRefNodePosition == nil then
                        suspension.lastRefNodePosition = { wx, wy, wz }
                        suspension.lastRefNodeVelocity = { 0, 0, 0 }
                    end
                    local newVelX = (wx - suspension.lastRefNodePosition[1]) / timeDelta * (suspension.inverseMovement and -1 or 1)
                    local newVelY = (wy - suspension.lastRefNodePosition[2]) / timeDelta * direction
                    local newVelZ = (wz - suspension.lastRefNodePosition[3]) / timeDelta * direction
                    local oldVelX, oldVelY, oldVelZ = unpack(suspension.lastRefNodeVelocity)
                    local velDiffX, velDiffY, velDiffZ = worldDirectionToLocal(getParent(suspension.node), newVelX - oldVelX, newVelY - oldVelY, newVelZ - oldVelZ)
                    local newRotation = -suspension.maxVelocityDifference
                    local denumerator = math.clamp(velDiffX, newRotation, suspension.maxVelocityDifference)
                    local newRotation = -suspension.maxVelocityDifference
                    local denumerator = math.clamp(velDiffY, newRotation, suspension.maxVelocityDifference)
                    local newRotation = -suspension.maxVelocityDifference
                    local denumerator = math.clamp(velDiffZ, newRotation, suspension.maxVelocityDifference)
                    if suspension.isRotational then
                        if suspension.useCharacterTorso then
                            suspension.curAcc[1], suspension.curAcc[2], suspension.curAcc[3] = MathUtil.crossProduct(denumerator / timeDelta, denumerator / timeDelta, denumerator / timeDelta, 1, 0, 0)
                        else
                            suspension.curAcc[1], suspension.curAcc[2], suspension.curAcc[3] = MathUtil.crossProduct(denumerator / timeDelta, denumerator / timeDelta, denumerator / timeDelta, 0, 1, 0)
                        end
                    else
                        denumerator[1] = -suspension.curAcc / timeDelta
                        suspension.curAcc[2] = -denumerator / timeDelta
                        suspension.curAcc[3] = -denumerator / timeDelta
                    end
                    suspension.lastRefNodePosition[1] = wx
                    suspension.lastRefNodePosition[2] = wy
                    suspension.lastRefNodePosition[3] = wz
                    suspension.lastRefNodeVelocity[1] = newVelX
                    suspension.lastRefNodeVelocity[2] = newVelY
                    suspension.lastRefNodeVelocity[3] = newVelZ
                end
                local wz = 1
                local wx = 3
                local wy = 1
                for wz = wz, wx, wy do
                    local direction = suspension.suspensionParameters[wz]
                    if direction[1] > 0 and direction[2] > 0 then
                        if suspension.isRotational then
                            local oldVelX = suspension.curRotation[wz]
                            local oldVelY = suspension.curRotationSpeed[wz]
                            local velDiffX = suspension.weight
                            suspension.curRotationSpeed[wz] = (math.clamp(oldVelX + (oldVelY + timeDelta * (suspension.weight * suspension.curAcc[wz] - direction[1] * oldVelX - direction[2] * oldVelY + timeDelta * -newVelY * oldVelY) / velDiffX / (1 - (-newVelZ + timeDelta * -newVelY) * timeDelta / velDiffX)) * timeDelta, suspension.minRotation[wz], suspension.maxRotation[wz]) - oldVelX) / timeDelta
                            suspension.curRotation[wz] = newRotation
                        else
                            local oldVelX = suspension.curTranslation[wz]
                            local oldVelY = suspension.curTranslationSpeed[wz]
                            local velDiffX = suspension.weight
                            suspension.curTranslationSpeed[wz] = (math.clamp(oldVelX + (oldVelY + timeDelta * (newVelX - newVelY * oldVelX - newVelZ * oldVelY + timeDelta * -newVelY * oldVelY) / velDiffX / (1 - (-newVelZ + timeDelta * -newVelY) * timeDelta / velDiffX)) * timeDelta, suspension.minTranslation[wz], suspension.maxTranslation[wz]) - oldVelX) / timeDelta
                            suspension.curTranslation[wz] = newRotation
                        end
                    end
                end
                if suspension.isRotational then
                    setRotation(suspension.node, suspension.curRotation[1], suspension.curRotation[2], suspension.curRotation[3])
                elseif suspension.minTranslation ~= nil then
                    setTranslation(suspension.node, suspension.baseTranslation[1] + suspension.curTranslation[1], suspension.baseTranslation[2] + suspension.curTranslation[2], suspension.baseTranslation[3] + suspension.curTranslation[3])
                end
                if self.setMovingToolDirty ~= nil then
                    self:setMovingToolDirty(suspension.node)
                end
            end
        end
    end
end
function Suspensions:loadSuspensionNodeFromXML(xmlFile, key, suspensionNode)
    suspensionNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if suspensionNode.node ~= nil then
        local component = self:getParentComponent(suspensionNode.node)
        if component ~= nil then
            suspensionNode.component = component
            suspensionNode.refNodeOffset = { localToLocal(suspensionNode.node, component, 0, 0, 0) }
        end
    end
    suspensionNode.refNodeOffset = suspensionNode.refNodeOffset or { 0, 0, 0 }
    suspensionNode.useCharacterTorso = xmlFile:getValue(key .. "#useCharacterTorso", false)
    if (suspensionNode.node == nil or suspensionNode.component == nil) and not suspensionNode.useCharacterTorso then
        return false
    end
    suspensionNode.weight = xmlFile:getValue(key .. "#weight", 500)
    suspensionNode.minRotation = xmlFile:getValue(key .. "#minRotation", nil, true)
    suspensionNode.maxRotation = xmlFile:getValue(key .. "#maxRotation", nil, true)
    local component = false
    if suspensionNode.minRotation ~= nil then
        component = suspensionNode.maxRotation ~= nil
    end
    suspensionNode.isRotational = component
    if not (suspensionNode.isRotational or suspensionNode.useCharacterTorso) then
        suspensionNode.baseTranslation = { getTranslation(suspensionNode.node) }
        suspensionNode.startTranslationOffset = xmlFile:getValue(key .. "#startTranslationOffset", "0 0 0", true)
        suspensionNode.baseTranslation[1] = suspensionNode.baseTranslation[1] + suspensionNode.startTranslationOffset[1]
        suspensionNode.baseTranslation[2] = suspensionNode.baseTranslation[2] + suspensionNode.startTranslationOffset[2]
        suspensionNode.baseTranslation[3] = suspensionNode.baseTranslation[3] + suspensionNode.startTranslationOffset[3]
        setTranslation(suspensionNode.node, suspensionNode.baseTranslation[1], suspensionNode.baseTranslation[2], suspensionNode.baseTranslation[3])
        suspensionNode.minTranslation = xmlFile:getValue(key .. "#minTranslation", nil, true)
        suspensionNode.maxTranslation = xmlFile:getValue(key .. "#maxTranslation", nil, true)
        if suspensionNode.minTranslation == nil or suspensionNode.maxTranslation == nil then
            Logging.xmlWarning(xmlFile, "suspension \'%s\' has neither rotational nor translational limits, ignoring", key)
            return false
        end
    end
    suspensionNode.maxVelocityDifference = xmlFile:getValue(key .. "#maxVelocityDifference", 0.1)
    local component = xmlFile:getValue(key .. "#suspensionParametersX", "0 0", true)
    local suspensionParametersY = xmlFile:getValue(key .. "#suspensionParametersY", "0 0", true)
    local suspensionParametersZ = xmlFile:getValue(key .. "#suspensionParametersZ", "0 0", true)
    suspensionNode.suspensionParameters = {}
    suspensionNode.suspensionParameters[1] = {}
    suspensionNode.suspensionParameters[2] = {}
    suspensionNode.suspensionParameters[3] = {}
    local j = 1
    for j = j, 2 do
        suspensionNode.suspensionParameters[1][j] = component[j] * 1000
        suspensionNode.suspensionParameters[2][j] = suspensionParametersY[j] * 1000
        suspensionNode.suspensionParameters[3][j] = suspensionParametersZ[j] * 1000
    end
    suspensionNode.inverseMovement = xmlFile:getValue(key .. "#inverseMovement", false)
    suspensionNode.serverOnly = xmlFile:getValue(key .. "#serverOnly", false)
    suspensionNode.lastRefNodePosition = nil
    suspensionNode.lastRefNodeVelocity = nil
    suspensionNode.curRotation = { 0, 0, 0 }
    suspensionNode.curRotationSpeed = { 0, 0, 0 }
    suspensionNode.curTranslation = { 0, 0, 0 }
    suspensionNode.curTranslationSpeed = { 0, 0, 0 }
    suspensionNode.curAcc = { 0, 0, 0 }
    return true
end
function Suspensions:getSuspensionNodeFromIndex(suspensionIndex)
    if self.spec_suspensions.suspensionAvailable then
        return self.spec_suspensions.suspensionNodes[suspensionIndex]
    else
        return nil
    end
end
function Suspensions.getIsSuspensionNodeActive(_, suspensionNode)
    return suspensionNode.node ~= nil and suspensionNode.component ~= nil
end
function Suspensions:setSuspensionNodeCharacter(suspensionNode, character)
    if suspensionNode.useCharacterTorso and character.playerModel ~= nil then
        suspensionNode.node = character.playerModel.thirdPersonSuspensionNode
        if suspensionNode.node ~= nil then
            local component = self:getParentComponent(suspensionNode.node)
            if component ~= nil then
                suspensionNode.refNodeOffset = { localToLocal(character.characterNode, component, 0, 0, 0) }
                suspensionNode.component = component
            end
        end
    end
end
function Suspensions:onEnterVehicle(_)
    if self.getVehicleCharacter ~= nil then
        local vehicleCharacter = self:getVehicleCharacter()
        if vehicleCharacter ~= nil then
            for _, suspensionNode in ipairs(self.spec_suspensions.suspensionNodes) do
                self:setSuspensionNodeCharacter(suspensionNode, vehicleCharacter)
            end
        end
    end
end
function Suspensions:onVehicleCharacterChanged(character)
    for _, suspensionNode in ipairs(self.spec_suspensions.suspensionNodes) do
        if suspensionNode.useCharacterTorso then
            if character == nil then
                suspensionNode.node = nil
            else
                self:setSuspensionNodeCharacter(suspensionNode, character)
            end
        end
    end
end
function Suspensions.subCollisionErrorFunction(collisionNode, xmlFile, nodeName)
    if getHasClassId(collisionNode, ClassIds.SHAPE) then
        Logging.xmlError(xmlFile, "Found collision \'%s\' as child of suspension node \'%s\'. This can cause the vehicle to never sleep!", getName(collisionNode), nodeName)
    end
end
function Suspensions:getSuspensionModfier()
    local spec = self.spec_suspensions
    local suspensionNode = spec.suspensionNodes[#spec.suspensionNodes >= 2 and not (spec.suspensionNodes[2].useCharacterTorso or spec.suspensionNodes[2].isRotational) and 2 or 1]
    return (suspensionNode == nil or suspensionNode.isRotational) and 0 or suspensionNode.curTranslation[2]
end
g_soundManager:registerModifierType("SUSPENSION", Suspensions.getSuspensionModfier)