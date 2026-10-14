DebugInfoTable = {}
local DebugInfoTable_mt = Class(DebugInfoTable, DebugElement)
function DebugInfoTable.new(customMt)
    -- upvalues: (copy) DebugInfoTable_mt
    local self = DebugInfoTable:superClass().new(customMt or DebugInfoTable_mt)
    self.rotX = 0
    self.rotY = 0
    self.rotZ = 0
    self.size = 0.25
    self.information = nil
    self.text = nil
    self.alignToGround = false
    return self
end
function DebugInfoTable:draw()
    DebugInfoTable.renderAtPosition(self.x, self.y, self.z, self.information, self.rotX, self.rotY, self.rotZ, self.size, self.color)
end
function DebugInfoTable.renderAtPosition(x, y, z, information, rx, ry, rz, size, color)
    setTextDepthTestEnabled(false)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    if color ~= nil then
        setTextColor(color:unpack())
    end
    setTextBold(false)
    if rx == nil then
        rx = 0
        ry = DebugUtil.getYRotatationToCamera(x, y, z)
        rz = 0
    end
    size = size or 0.5
    local yOffset = 0
    local i = #information
    for i = i, 1, -1 do
        local info = information[i]
        local content = info.content
        local j = #content
        for j = j, 1, -1 do
            local pair = content[j]
            local value = pair.value
            if pair.color ~= nil then
                setTextColor(pair.color:unpack())
            end
            local lineSize = size * (pair.sizeFactor or 1)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText3D(x, y + yOffset, z, rx, ry, rz, lineSize, pair.name)
            setTextAlignment(RenderText.ALIGN_LEFT)
            if type(value) == "number" then
                renderText3D(x, y + yOffset, z, rx, ry, rz, lineSize, " " .. string.format("%.4f", value))
            else
                renderText3D(x, y + yOffset, z, rx, ry, rz, lineSize, " " .. tostring(value))
            end
            if pair.color ~= nil then
                setTextColor(color:unpack())
            end
            yOffset = yOffset + lineSize
        end
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        renderText3D(x, y + yOffset, z, rx, ry, rz, size, info.title)
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        yOffset = yOffset + 2 * size
    end
    setTextDepthTestEnabled(true)
end
function DebugInfoTable.renderAtNode(node, information, size, color)
    local x, y, z = getWorldTranslation(node)
    DebugInfoTable.renderAtPosition(x, y, z, information, nil, nil, nil, size, color)
end
function DebugInfoTable:createWithNode(node, information, size)
    local x, y, z = getWorldTranslation(node)
    local rotX, rotY, rotZ = getWorldRotation(node)
    self:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, information, size)
    return self
end
function DebugInfoTable:createWithNodeToCamera(node, information, yOffset, size)
    local x, y, z = localToWorld(node, 0, yOffset or 0, 0)
    local cx, cy, cz = getWorldTranslation(g_cameraManager:getActiveCamera())
    local dirX, _, dirZ = MathUtil.vector3Normalize(cx - x, cy - y, cz - z)
    self:createWithWorldPosAndRot(x, y, z, 0, MathUtil.getYRotationFromDirection(dirX, dirZ), 0, information, size or 0.05)
    return self
end
function DebugInfoTable:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, information, size)
    self.x = x
    self.y = y
    self.z = z
    self.rotX = rotX
    self.rotY = rotY
    self.rotZ = rotZ
    self.information = information
    self.size = (size or 0.05) * 2.5
    return self
end