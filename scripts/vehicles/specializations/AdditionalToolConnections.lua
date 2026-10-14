AdditionalToolConnections = {}
function AdditionalToolConnections.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function AdditionalToolConnections.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AdditionalToolConnections")
    schema:register(XMLValueType.STRING, "vehicle.additionalToolConnections.connection(?)#id", "Identifier of the tool connection")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.additionalToolConnections.connection(?)#movingPartNode", "Node of movingPart to set the reference node to the connection node")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.additionalToolConnections.connection(?)")
    schema:addDelayedRegistrationFunc("AttacherJoint", function(cSchema, cKey)
        cSchema:register(XMLValueType.STRING, cKey .. ".additionalToolConnection(?)#id", "Identifier of the tool connection")
        cSchema:register(XMLValueType.NODE_INDEX, cKey .. ".additionalToolConnection(?)#node", "Node to connect to")
    end)
    schema:setXMLSpecializationType()
end
function AdditionalToolConnections.registerFunctions(vehicleType) end
function AdditionalToolConnections.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", AdditionalToolConnections.loadAttacherJointFromXML)
end
function AdditionalToolConnections.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AdditionalToolConnections)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", AdditionalToolConnections)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", AdditionalToolConnections)
end
function AdditionalToolConnections:onPostLoad(_)
    local spec = self.spec_additionalToolConnections
    spec.additionalToolConnections = {}
    self.xmlFile:iterate("vehicle.additionalToolConnections.connection", function(_, connectionKey)
        -- upvalues: (copy) self, (copy) spec
        local id = self.xmlFile:getValue(connectionKey .. "#id")
        local movingPartNode = self.xmlFile:getValue(connectionKey .. "#movingPartNode", nil, self.components, self.i3dMappings)
        if id == nil or movingPartNode == nil then
            Logging.xmlWarning(self.xmlFile, "Failed to load additionalToolConnection \'%s\'", connectionKey)
            return
        elseif self:getMovingPartByNode(movingPartNode) == nil then
            Logging.xmlWarning(self.xmlFile, "Failed to find moving part for \'%s\' in \'%s\'", getName(movingPartNode), connectionKey)
        else
            local entry = {
                ["id"] = id,
                ["movingPartNode"] = movingPartNode,
                ["objectChanges"] = {}
            }
            ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, connectionKey, entry.objectChanges, self.components, self)
            ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty)
            table.insert(spec.additionalToolConnections, entry)
        end
    end)
end
function AdditionalToolConnections:loadAttacherJointFromXML(superFunc, attacherJoint, xmlFile, baseName, index, ...)
    if not superFunc(self, attacherJoint, xmlFile, baseName, index, ...) then
        return false
    end
    attacherJoint.additionalToolConnections = attacherJoint.additionalToolConnections or {}
    xmlFile:iterate(baseName .. ".additionalToolConnection", function(_, connectionKey)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) attacherJoint
        local id = xmlFile:getValue(connectionKey .. "#id")
        local node = xmlFile:getValue(connectionKey .. "#node", nil, self.components, self.i3dMappings)
        if id == nil or node == nil then
            Logging.xmlWarning(xmlFile, "Failed to load additionalToolConnection \'%s\'", connectionKey)
        else
            attacherJoint.additionalToolConnections[id] = node
        end
    end)
    return true
end
function AdditionalToolConnections:onPostAttach(attacherVehicle, _, jointDescIndex, _)
    local jointDesc = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
    if jointDesc.additionalToolConnections ~= nil then
        local i = 1
        for i = i, #self.spec_additionalToolConnections.additionalToolConnections do
            local connection = spec.additionalToolConnections[i]
            local node = jointDesc.additionalToolConnections[connection.id]
            if node ~= nil then
                self:setMovingPartReferenceNode(connection.movingPartNode, node, true)
                ObjectChangeUtil.setObjectChanges(connection.objectChanges, true, self, self.setMovingToolDirty)
            end
        end
    end
end
function AdditionalToolConnections:onPreDetach(_, _)
    local spec = self.spec_additionalToolConnections
    local i = 1
    for i = i, #spec.additionalToolConnections do
        local connection = spec.additionalToolConnections[i]
        self:setMovingPartReferenceNode(connection.movingPartNode, nil, false)
        ObjectChangeUtil.setObjectChanges(connection.objectChanges, false, self, self.setMovingToolDirty)
    end
end