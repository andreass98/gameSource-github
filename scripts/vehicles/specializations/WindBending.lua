WindBending = {}
function WindBending.prerequisitesPresent(specializations)
    return true
end
function WindBending.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WindBending")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.windBending.windBendingNodes.windBendingNode(?)#node", "Shader node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.windBending.windBendingNodes.windBendingNode(?)#decalNode", "Extra node that gets the exact same shader parameters")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.windBending.windBendingNodes.windBendingNode(?)#speedReferenceNode", "Reference node to calculate speed of wind")
    schema:register(XMLValueType.FLOAT, "vehicle.windBending.windBendingNodes.windBendingNode(?)#maxBending", "Bending in meters", 0.15)
    schema:register(XMLValueType.FLOAT, "vehicle.windBending.windBendingNodes.windBendingNode(?)#maxBendingNeg", "Negative bending in meters (used if the vehicle drives in reverse)", "same as #maxBending")
    schema:register(XMLValueType.FLOAT, "vehicle.windBending.windBendingNodes.windBendingNode(?)#maxBendingSpeed", "Speed at which max bending state is reached in kmph", 20)
    schema:setXMLSpecializationType()
end
function WindBending.registerFunctions(vehicleType) end
function WindBending.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WindBending)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WindBending)
end
function WindBending:onLoad(_)
    local spec = self.spec_windBending
    if self.isClient then
        spec.windBending = {}
        self.xmlFile:iterate("vehicle.windBending.windBendingNodes.windBendingNode", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local entry = {
                ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            }
            if entry.node == nil then
                Logging.xmlError(self.xmlFile, "Unable to load wind bending node from xml. Node not found. \'%s\'", key)
                return
            elseif getHasClassId(entry.node, ClassIds.SHAPE) and getHasShaderParameter(entry.node, "directionBend") then
                entry.speedReferenceNode = self.xmlFile:getValue(key .. "#speedReferenceNode", entry.node, self.components, self.i3dMappings)
                entry.parentComponent = self:getParentComponent(entry.speedReferenceNode)
                entry.maxBending = self.xmlFile:getValue(key .. "#maxBending", 0.15)
                entry.maxBendingNeg = self.xmlFile:getValue(key .. "#maxBendingNeg", entry.maxBending)
                entry.maxBendingSpeed = self.xmlFile:getValue(key .. "#maxBendingSpeed", 20)
                entry.decalNode = self.xmlFile:getValue(key .. "#decalNode", nil, self.components, self.i3dMappings)
                entry.lastPosition = nil
                table.insert(spec.windBending, entry)
            else
                Logging.xmlError(self.xmlFile, "Unable to load wind bending node from xml. Node has not shader parameter \'directionBend\'. \'%s\'", key)
            end
        end)
    end
    if not self.isClient or #spec.windBending == 0 then
        SpecializationUtil.removeEventListener(self, "onUpdate", WindBending)
    end
end
function WindBending:onUpdate(_, _, _, _)
    local spec = self.spec_windBending
    local lastSpeed = self:getLastSpeed()
    local i = 1
    for i = i, #spec.windBending do
        local windBendingNode = spec.windBending[i]
        local x, y, z = localToWorld(windBendingNode.speedReferenceNode, 0, 0, 0)
        if windBendingNode.lastPosition == nil then
            windBendingNode.lastPosition = { x, y, z }
        end
        local vx = (x - windBendingNode.lastPosition[1]) * 10
        local vy = (y - windBendingNode.lastPosition[2]) * 10
        local vz = (z - windBendingNode.lastPosition[3]) * 10
        if vx ~= 0 or (vy ~= 0 or vz ~= 0) then
            local maxBending, bendingAmount, vz = worldDirectionToLocal(getParent(windBendingNode.node), vx, vy, vz)
            local maxBending, bendingAmount, vz = MathUtil.vector3Normalize(maxBending, bendingAmount, vz)
            local bendingAmount = (self.movingDirection >= 0 and windBendingNode.maxBending or windBendingNode.maxBendingNeg) * (lastSpeed / windBendingNode.maxBendingSpeed)
            g_animationManager:setPrevShaderParameter(windBendingNode.node, "directionBend", maxBending, bendingAmount, vz, bendingAmount, false, "prevDirectionBend")
            if windBendingNode.decalNode ~= nil then
                g_animationManager:setPrevShaderParameter(windBendingNode.decalNode, "directionBend", maxBending, bendingAmount, vz, bendingAmount, false, "prevDirectionBend")
            end
        end
        windBendingNode.lastPosition[1] = x
        windBendingNode.lastPosition[2] = y
        windBendingNode.lastPosition[3] = z
    end
end