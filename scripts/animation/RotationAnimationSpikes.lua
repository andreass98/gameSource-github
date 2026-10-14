RotationAnimationSpikes = {}
local RotationAnimationSpikes_mt = Class(RotationAnimationSpikes, RotationAnimation)
function RotationAnimationSpikes.new(customMt)
    -- upvalues: (copy) RotationAnimationSpikes_mt
    return RotationAnimation.new(customMt or RotationAnimationSpikes_mt)
end
function RotationAnimationSpikes:load(xmlFile, key, rootNodes, owner, i3dMapping)
    if RotationAnimationSpikes:superClass().load(self, xmlFile, key, rootNodes, owner, i3dMapping) == nil then
        return nil
    end
    if table.size(self.nodes) ~= 1 then
        Logging.xmlWarning(xmlFile, "RotationAnimationSpikes does only support one link node in \'%s\'", key)
        return nil
    end
    self.spikeRotAxis = xmlFile:getValue(key .. ".spikes#rotAxis", 3)
    self.spikeMaxRot = xmlFile:getValue(key .. ".spikes#maxRot", 0)
    self.spikeTransAxis = xmlFile:getValue(key .. ".spikes#transAxis")
    self.spikeMaxTrans = xmlFile:getValue(key .. ".spikes#maxTrans", 0)
    self.spikeInverted = xmlFile:getValue(key .. ".spikes#inverted", false)
    self.moveUpStart, self.moveUpEnd = xmlFile:getValue(key .. ".spikes#moveUpRange")
    self.moveDownStart, self.moveDownEnd = xmlFile:getValue(key .. ".spikes#moveDownRange")
    if self.moveUpStart == nil or (self.moveUpEnd == nil or (self.moveDownStart == nil or self.moveDownEnd == nil)) then
        Logging.xmlWarning(xmlFile, "Incomplete moveUp/moveDown range given for \'%s", key)
        return nil
    end
    self.rotOffset = self.currentRot
    self.rotDirection = math.sign(self.rotSpeed)
    if self.rotDirection < 0 then
        self.moveUpStart = -self.moveUpStart
        self.moveUpEnd = -self.moveUpEnd
        self.moveDownStart = -self.moveDownStart
        self.moveDownEnd = -self.moveDownEnd
    end
    self.moveUpStart = self.moveUpStart + self.rotOffset
    self.moveUpEnd = self.moveUpEnd + self.rotOffset
    self.moveDownStart = self.moveDownStart + self.rotOffset
    self.moveDownEnd = self.moveDownEnd + self.rotOffset
    self.spikeOffset = 1
    self.spikes = {}
    xmlFile:iterate(key .. ".spikes.spike", function(_, spikeKey)
        -- upvalues: (copy) xmlFile, (copy) rootNodes, (copy) i3dMapping, (copy) self
        local spike = {
            ["node"] = xmlFile:getValue(spikeKey .. "#node", nil, rootNodes, i3dMapping)
        }
        if spike.node ~= nil then
            spike.initialRot = { getRotation(spike.node) }
            local dx = nil
            local dy = nil
            if self.rotAxis == 1 then
                _, dx, dy = localToLocal(spike.node, self.rootNode, 0, 0, 0)
            elseif self.rotAxis == 2 then
                dx, _, dy = localToLocal(spike.node, self.rootNode, 0, 0, 0)
            elseif self.rotAxis == 3 then
                dx, dy, _ = localToLocal(spike.node, self.rootNode, 0, 0, 0)
            end
            self.spikeOffset = MathUtil.vector2Length(dx, dy)
            local dx = dx / self.spikeOffset
            local dy = dy / self.spikeOffset
            spike.rotationOffset = MathUtil.getYRotationFromDirection(dx, dy)
            if self.rotAxis == 1 then
                spike.rotationOffset = -spike.rotationOffset
            end
            if spike.rotationOffset < 0 then
                spike.rotationOffset = 6.283185307179586 + spike.rotationOffset
            end
            if self.spikeTransAxis ~= nil then
                spike.startTrans = { getTranslation(spike.node) }
                if self.spikeTransAxis == 1 then
                    spike.endTrans = { localToLocal(spike.node, getParent(spike.node), self.spikeMaxTrans, 0, 0) }
                elseif self.spikeTransAxis == 2 then
                    spike.endTrans = { localToLocal(spike.node, getParent(spike.node), 0, self.spikeMaxTrans, 0) }
                else
                    spike.endTrans = { localToLocal(spike.node, getParent(spike.node), 0, 0, self.spikeMaxTrans) }
                end
            end
            spike.alpha = nil
            table.insert(self.spikes, spike)
        end
    end)
    self:updateSpikes()
    return self
end
function RotationAnimationSpikes:update(dt)
    RotationAnimationSpikes:superClass().update(self, dt)
    if VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
        self:drawDebug()
    end
    if self.currentAlpha > 0 then
        self:updateSpikes()
    end
end
function RotationAnimationSpikes:updateSpikes()
    for _, spike in ipairs(self.spikes) do
        local value = (self.currentRot + spike.rotationOffset) % 6.283185307179586
        local alpha = nil
        local s = self.moveUpEnd
        local e = self.moveDownStart
        local invValue = value - 6.283185307179586
        local isUp
        if e < s then
            isUp = value <= s and e <= value and true or invValue <= s and e <= invValue
        else
            isUp = s <= value and value <= e and true or s <= invValue and invValue <= e
        end
        if isUp then
            alpha = 1
        else
            local s = self.moveUpStart
            local e = self.moveUpEnd
            local invValue = value - 6.283185307179586
            local alpha
            if e < s then
                if value <= s and e <= value then
                    alpha = true
                    invValue = value
                elseif invValue <= s and e <= invValue then
                    alpha = true
                else
                    alpha = false
                    invValue = value
                end
            elseif s <= value and value <= e then
                alpha = true
                invValue = value
            elseif s <= invValue and invValue <= e then
                alpha = true
            else
                alpha = false
                invValue = value
            end
            local alpha, s
            if alpha then
                if e < s then
                    alpha = (invValue - e) / (s - e)
                else
                    alpha = (invValue - s) / (e - s)
                    s = true
                end
            else
                s = false
                alpha = nil
            end
            if s then
            else
                local inRange = self.moveDownStart
                local alpha = self.moveDownEnd
                local invValue = value - 6.283185307179586
                local value
                if alpha < inRange then
                    if value <= inRange and alpha <= value then
                        value = true
                    elseif invValue <= inRange and alpha <= invValue then
                        value = true
                        value = invValue
                    else
                        value = false
                    end
                elseif inRange <= value and value <= alpha then
                    value = true
                elseif inRange <= invValue and invValue <= alpha then
                    value = true
                    value = invValue
                else
                    value = false
                end
                local value, invValue
                if value then
                    if alpha < inRange then
                        invValue = true
                    else
                        invValue = true
                    end
                else
                    invValue = false
                    value = nil
                end
                if invValue then
                    alpha = 1 - value
                end
            end
            if alpha ~= nil and self.rotDirection < 0 then
            end
        end
        local alpha = alpha or 0
        if self.spikeInverted then
        end
        if alpha ~= spike.alpha then
            spike.alpha = alpha
            if self.spikeTransAxis == nil then
                if self.spikeRotAxis == 1 then
                    setRotation(spike.node, spike.initialRot[1] + self.spikeMaxRot * alpha, spike.initialRot[2], spike.initialRot[3])
                elseif self.spikeRotAxis == 2 then
                    setRotation(spike.node, spike.initialRot[1], spike.initialRot[2] + s, spike.initialRot[3])
                else
                    setRotation(spike.node, spike.initialRot[1], spike.initialRot[2], spike.initialRot[3] + s)
                end
            else
                local s, e, invValue = MathUtil.vector3ArrayLerp(spike.startTrans, spike.endTrans, alpha)
                setTranslation(spike.node, s, e, invValue)
            end
        end
    end
end
function RotationAnimationSpikes:drawDebug()
    local ox, oy, oz = getTranslation(self.rootNode)
    RotationAnimationSpikes.drawDebugCircleRange(getParent(self.rootNode), ox, oy, oz, self.spikeOffset, 20, self.rotAxis, self.moveUpStart, self.moveUpEnd, 1)
    RotationAnimationSpikes.drawDebugCircleRange(getParent(self.rootNode), ox, oy, oz, self.spikeOffset, 20, self.rotAxis, self.moveDownStart, self.moveDownEnd, -1)
    local x1, y1, z1 = getWorldTranslation(self.rootNode)
    local x2, y2, z2 = localToWorld(self.rootNode, 0, 0, 0.75)
    drawDebugLine(x1, y1, z1, 0, 1, 1, x2, y2, z2, 0, 1, 1)
    local x1 = string.format
    Utils.renderTextAtWorldPosition(x1, y1, z1, x1("%.1f\194\176", (math.deg(self.currentRot % 6.283185307179586))), 0.01)
    local i = 1
    for i = i, #self.spikes do
        local spike = self.spikes[i]
        local x1, y1, z1 = getWorldTranslation(spike.node)
        Utils.renderTextAtWorldPosition(x1, y1, z1, string.format("%s", getName(spike.node):sub(-3)), 0.006)
    end
end
function RotationAnimationSpikes.registerAnimationClassXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".spikes#moveUpRange", "(RotationAnimationSpikes) Move up range")
    schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".spikes#moveDownRange", "(RotationAnimationSpikes) Move down range")
    schema:register(XMLValueType.INT, basePath .. ".spikes#rotAxis", "(RotationAnimationSpikes) Rotation axis", 3)
    schema:register(XMLValueType.ANGLE, basePath .. ".spikes#maxRot", "(RotationAnimationSpikes) Max. spike rotation")
    schema:register(XMLValueType.INT, basePath .. ".spikes#transAxis", "(RotationAnimationSpikes) Translation axis (disables the rotation adjustment of the spike)", 3)
    schema:register(XMLValueType.FLOAT, basePath .. ".spikes#maxTrans", "(RotationAnimationSpikes) Max. spike translation")
    schema:register(XMLValueType.BOOL, basePath .. ".spikes#inverted", "(RotationAnimationSpikes) Min. and max. rotation/translation of spikes are inverted", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".spikes.spike(?)#node", "(RotationAnimationSpikes) Spike node")
end
local DEBUG_TEXT_COLOR = {
    0,
    1,
    1,
    1
}
local DEBUG_UP_COLOR = {
    0,
    1,
    0,
    1
}
local DEBUG_DOWN_COLOR = {
    1,
    0,
    0,
    1
}
function RotationAnimationSpikes.drawDebugCircleRange(node, ox, oy, oz, radius, steps, axis, minRot, maxRot, direction)
    -- upvalues: (copy) DEBUG_UP_COLOR, (copy) DEBUG_DOWN_COLOR, (copy) DEBUG_TEXT_COLOR
    local i = 1
    for i = i, steps do
        local a1 = 1.5707963267948966 + minRot + (i - 1) / steps * (maxRot - minRot)
        local a2 = 1.5707963267948966 + minRot + i / steps * range
        local c1 = math.cos(a1) * radius
        local s1 = math.sin(a1) * radius
        local c2 = math.cos(a2) * radius
        local s2 = math.sin(a2) * radius
        local r1, g1, b1, r1, g1, b1
        if axis == 1 then
            r1, g1, b1 = localToWorld(node, ox + 0, oy + c1, oz + s1)
            r1, g1, b1 = localToWorld(node, ox + 0, oy + c2, oz + s2)
        elseif axis == 2 then
            r1, g1, b1 = localToWorld(node, ox - c1, oy + 0, oz + s1)
            r1, g1, b1 = localToWorld(node, ox - c2, oy + 0, oz + s2)
        else
            r1, g1, b1 = localToWorld(node, ox - c1, oy + s1, oz + 0)
            r1, g1, b1 = localToWorld(node, ox - c2, oy + s2, oz + 0)
        end
        local r1, g1, b1 = MathUtil.vector3Lerp((direction > 0 and DEBUG_UP_COLOR or DEBUG_DOWN_COLOR)[1], (direction > 0 and DEBUG_UP_COLOR or DEBUG_DOWN_COLOR)[2], (direction > 0 and DEBUG_UP_COLOR or DEBUG_DOWN_COLOR)[3], (direction > 0 and DEBUG_DOWN_COLOR or DEBUG_UP_COLOR)[1], (direction > 0 and DEBUG_DOWN_COLOR or DEBUG_UP_COLOR)[2], (direction > 0 and DEBUG_DOWN_COLOR or DEBUG_UP_COLOR)[3], (i - 1) / (steps - 1))
        local r2, g2, b2 = MathUtil.vector3Lerp(startColor[1], startColor[2], startColor[3], endColor[1], endColor[2], endColor[3], i / (steps - 1))
        drawDebugLine(r1, g1, b1, r1, g1, b1, r1, g1, b1, r2, g2, b2)
        if i == math.floor(steps * 0.5) then
            Utils.renderTextAtWorldPosition((r1 + r1) * 0.5, (g1 + g1) * 0.5, (b1 + b1) * 0.5, string.format("%s %.1f\194\176 - %.1f\194\176", direction > 0 and "up" or "down", math.deg(minRot), (math.deg(maxRot))), 0.0075, nil, unpack(DEBUG_TEXT_COLOR))
        end
    end
end