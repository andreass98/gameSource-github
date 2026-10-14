ThreePartOverlay = {}
if g_threePartTest ~= nil then
    g_threePartTest:delete()
    g_threePartTest = nil
end
local ThreePartOverlay_mt = Class(ThreePartOverlay)
function ThreePartOverlay.new(custom_mt)
    -- upvalues: (copy) ThreePartOverlay_mt
    local self = setmetatable({}, custom_mt or ThreePartOverlay_mt)
    self.dirX = 1
    self.dirY = 0
    return self
end
function ThreePartOverlay:delete()
    if self.leftPart ~= nil then
        self.leftPart:delete()
        self.leftPart = nil
    end
    if self.middlePart ~= nil then
        self.middlePart:delete()
        self.middlePart = nil
    end
    if self.rightPart ~= nil then
        self.rightPart:delete()
        self.rightPart = nil
    end
end
function ThreePartOverlay:setLeftPart(sliceId, width, height)
    if sliceId ~= nil then
        if self.leftPart == nil then
            self.leftPart = g_overlayManager:createOverlay(sliceId, 0, 0, width, height)
        else
            self.leftPart:setSliceId(sliceId)
        end
    end
    if self.leftPart ~= nil then
        self.leftPart:setDimension(width, height)
    end
end
function ThreePartOverlay:setMiddlePart(sliceId, width, height)
    if sliceId ~= nil then
        if self.middlePart ~= nil then
            self.middlePart:delete()
        end
        self.middlePart = g_overlayManager:createOverlay(sliceId, 0, 0, width, height)
    end
    if self.middlePart ~= nil then
        self.middlePart:setDimension(width, height)
    end
end
function ThreePartOverlay:setRightPart(sliceId, width, height)
    if sliceId ~= nil then
        if self.rightPart ~= nil then
            self.rightPart:delete()
        end
        self.rightPart = g_overlayManager:createOverlay(sliceId, 0, 0, width, height)
    end
    if self.rightPart ~= nil then
        self.rightPart:setDimension(width, height)
    end
end
function ThreePartOverlay:setColor(r, g, b, a)
    if self.leftPart ~= nil then
        self.leftPart:setColor(r, g, b, a)
    end
    if self.middlePart ~= nil then
        self.middlePart:setColor(r, g, b, a)
    end
    if self.rightPart ~= nil then
        self.rightPart:setColor(r, g, b, a)
    end
end
function ThreePartOverlay:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
end
function ThreePartOverlay:setRotation(rotation)
    self.rotation = rotation + 1.5707963267948966
    if self.leftPart ~= nil then
        self.leftPart:setRotation(rotation, 0, 0)
    end
    if self.middlePart ~= nil then
        self.middlePart:setRotation(rotation, 0, 0)
    end
    if self.rightPart ~= nil then
        self.rightPart:setRotation(rotation, 0, 0)
    end
    self.dirX = math.sin(self.rotation)
    self.dirY = -math.cos(self.rotation)
end
function ThreePartOverlay:render()
    local x = self.x
    local y = self.y
    if self.leftPart ~= nil then
        self.leftPart:setPosition(x, y)
        self.leftPart:render()
        x = x + self.dirX * self.leftPart.width
        y = y + self.dirY * self.leftPart.width * g_screenAspectRatio
    end
    if self.middlePart ~= nil then
        self.middlePart:setPosition(x, y)
        self.middlePart:render()
        x = x + self.dirX * self.middlePart.width
        y = y + self.dirY * self.middlePart.width * g_screenAspectRatio
    end
    if self.rightPart ~= nil then
        self.rightPart:setPosition(x, y)
        self.rightPart:render()
    end
end
function ThreePartOverlay.renderTest()
    if g_threePartTest == nil then
        g_threePartTest = ThreePartOverlay.new()
        local leftX, leftY = getNormalizedScreenValues(25, 25)
        g_threePartTest:setLeftPart("gui.progressbar_left", leftX, leftY)
        local middleX, middleY = getNormalizedScreenValues(500, 25)
        g_threePartTest:setMiddlePart("gui.progressbar_middle", middleX, middleY)
        local rightX, rightY = getNormalizedScreenValues(25, 25)
        g_threePartTest:setRightPart("gui.progressbar_right", rightX, rightY)
        g_threePartTest:setPosition(0.5, 0.5)
        g_threePartTest:setColor(1, 1, 1, 1)
        g_threePartTest:setRotation(-2.0943951023931953)
    end
    g_threePartTest:render()
    drawPoint(0.5, 0.5, g_pixelSizeX, g_pixelSizeY, 1, 0, 0, 1)
end