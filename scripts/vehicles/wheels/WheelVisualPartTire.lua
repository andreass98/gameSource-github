WheelVisualPartTire = {}
local WheelVisualPartTire_mt = Class(WheelVisualPartTire, WheelVisualPart)
function WheelVisualPartTire.new(name, visualWheel, linkNode, _)
    -- upvalues: (copy) WheelVisualPartTire_mt
    local self = WheelVisualPart.new(name, visualWheel, linkNode, WheelVisualPartTire_mt)
    self.deformation = 0
    self.derformationPrevDirty = false
    return self
end
function WheelVisualPartTire:loadFromXML(xmlObject, key)
    if not WheelVisualPartTire:superClass().loadFromXML(self, xmlObject, key) then
        return false
    end
    self.maxDeformation = xmlObject:getValue(key .. "#maxDeformation", 0)
    self.initialDeformation = xmlObject:getValue(key .. "#initialDeformation", (math.min(0.04, self.maxDeformation * 0.6)))
    return true
end
function WheelVisualPartTire:update(_, _, _, _, suspensionLength, _, changed)
    if self.node ~= nil and Platform.gameplay.wheelVisualPressure then
        local prevDeformation = self.initialDeformation - suspensionLength
        local deformation = math.clamp(prevDeformation, 0, self.maxDeformation)
        local prevDeformation = nil
        local curDeformation = nil
        if math.abs(deformation - self.deformation) > Platform.gameplay.wheelVisualPressureUpdateThreshold then
            prevDeformation = self.deformation
            self.deformation = deformation
            self.derformationPrevDirty = true
            changed = true
            curDeformation = deformation
        end
        if curDeformation == nil and self.derformationPrevDirty then
            prevDeformation = self.deformation
            curDeformation = self.deformation
            self.derformationPrevDirty = false
        end
        if curDeformation ~= nil then
            for _, tireNode in ipairs(self.tireNodes) do
                setShaderParameter(tireNode, "morphPos", nil, nil, nil, curDeformation, false)
                setShaderParameter(tireNode, "prevMorphPos", nil, nil, nil, prevDeformation, false)
            end
        end
        suspensionLength = suspensionLength + deformation
    end
    return changed, suspensionLength
end
function WheelVisualPartTire:setNode(node)
    WheelVisualPartTire:superClass().setNode(self, node)
    self.tireNodes = {}
    if getHasClassId(self.node, ClassIds.SHAPE) and (getHasShaderParameter(self.node, "morphPos") or getHasShaderParameter(self.node, "morphPosition")) then
        table.insert(self.tireNodes, self.node)
    end
    I3DUtil.iterateRecursively(node, function(subNode)
        -- upvalues: (copy) self
        if getHasClassId(subNode, ClassIds.SHAPE) and (getHasShaderParameter(subNode, "morphPos") or getHasShaderParameter(subNode, "morphPosition")) then
            table.insert(self.tireNodes, subNode)
        end
    end)
    for _, tireNode in ipairs(self.tireNodes) do
        if getHasShaderParameter(tireNode, "morphPos") then
            local x, y, z, _ = getShaderParameter(tireNode, "morphPos")
            setShaderParameter(tireNode, "morphPos", nil, nil, nil, 0, false)
            setShaderParameter(tireNode, "prevMorphPos", x, y, z, 0, false)
        elseif getHasShaderParameter(tireNode, "morphPosition") then
            local x, y, z, _ = getShaderParameter(tireNode, "morphPosition")
            setShaderParameter(tireNode, "morphPos", x, y, z, 0, false)
            setShaderParameter(tireNode, "prevMorphPos", x, y, z, 0, false)
        end
    end
end
function WheelVisualPartTire.registerXMLPaths(schema, key, name)
    WheelVisualPart.registerXMLPaths(schema, key, name)
    schema:register(XMLValueType.FLOAT, key .. "#maxDeformation", "Max. deformation", 0)
    schema:register(XMLValueType.FLOAT, key .. "#initialDeformation", "Tire deformation at initial compression value", "min. 0.04 and max. 60% of the deformation")
    schema:register(XMLValueType.BOOL, key .. "#hasMudMesh", "Tire has a mud mesh included", false)
end