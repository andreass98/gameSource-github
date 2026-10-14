DebugText3D = {}
local DebugText3D_mt = Class(DebugText3D, DebugElement)
function DebugText3D.new(customMt)
    -- upvalues: (copy) DebugText3D_mt
    local self = DebugText3D:superClass().new(customMt or DebugText3D_mt)
    self.alignment = RenderText.ALIGN_CENTER
    self.verticalAlignment = RenderText.VERTICAL_ALIGN_MIDDLE
    self.size = 0.1
    return self
end
function DebugText3D:draw()
    DebugText3D.renderAtPosition(self.x, self.y, self.z, self.rx, self.ry, self.rz, self.text, self.color, self.size, self.alignment, self.verticalAlignment)
end
function DebugText3D.renderAtPosition(x, y, z, rx, ry, rz, text, color, size, alignment, verticalAlignment)
    setTextAlignment(alignment or RenderText.ALIGN_CENTER)
    setTextVerticalAlignment(verticalAlignment or RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false)
    setTextColor((color or Color.PRESETS.WHITE):unpack())
    renderText3D(x, y, z, rx, ry, rz, size, text)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
end
function DebugText3D.renderAtNode(node, text, color, size, alignment, verticalAlignment)
    local x, y, z = getWorldTranslation(node)
    local rx, ry, rz = getWorldRotation(node)
    DebugText3D.renderAtPosition(x, y, z, rx, ry, rz, text, color, size, alignment, verticalAlignment)
end
function DebugText3D:createWithNode(node, text, size)
    local x, y, z = getWorldTranslation(node)
    local rx, ry, rz = getWorldRotation(node)
    self:createWithWorldPos(x, y, z, rx, ry, rz, text, size)
    return self
end
function DebugText3D:createWithWorldPos(x, y, z, rx, ry, rz, text, size)
    self.x = x
    self.y = y
    self.z = z
    self.rx = rx
    self.ry = ry
    self.rz = rz
    self.text = text
    self.size = size or 0.02
    return self
end