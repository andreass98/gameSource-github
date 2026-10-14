TestPolygon = {}
function TestPolygon.init()
    local self = TestPolygon
    setEnablePostFx(false)
    self.camera = createCamera("Test", 1.2217304763960306, 0.001, 1000)
    g_cameraManager:addCamera(self.camera, nil, false)
    link(getRootNode(), self.camera)
    g_cameraManager:setActiveCamera(self.camera)
    setTranslation(self.camera, 0, 2, 0)
    setRotation(self.camera, -1.5707963267948966, 0, 0)
    self.debugPolygon = DebugPolygon.new()
    self.debugPoint = DebugPoint.new()
    self.debugCircle = DebugCircle.new()
    self.generatePolygon()
end
function TestPolygon.generatePolygon()
    local self = TestPolygon
    g_debugManager:removeGroup("default")
    local vertices = {
        math.random(),
        0,
        math.random(),
        math.random(),
        0,
        -math.random(),
        -math.random(),
        0,
        -math.random(),
        -math.random(),
        0,
        math.random(),
        math.random(),
        0,
        math.random()
    }
    self.debugPolygon:create(vertices):setColor(Color.new(1, 1, 1, 0.2)):addToManager()
    self.polygon = Polygon2D.new()
    self.polygon:setVerticesFromXYZ(vertices)
    local vMinX, vMaxX, vMinZ, vMaxZ = self.polygon:getBoundingBox()
    local hull = self.polygon:getConvexHull()
    self.hullVis = DebugPath.new()
    local i = 1
    for i = i, #hull - 1, 2 do
        DebugPoint.new():createWithWorldPos(hull[i], 0, hull[i + 1]):setColor(Color.PRESETS.YELLOW):addToManager()
        self.hullVis:addPoint(hull[i], 0, hull[i + 1])
    end
    self.hullVis:addPoint(hull[1], 0, hull[2])
    self.hullVis:setColor(Color.new(0, 0, 1, 0.2)):addToManager()
    self.pointX = MathUtil.randomFloat(vMinX * 1.1, vMaxX * 1.1)
    self.pointZ = MathUtil.randomFloat(vMinZ * 1.1, vMaxZ * 1.1)
    self.debugPoint:createWithWorldPos(self.pointX, 0.03, self.pointZ):setColor(Color.PRESETS.BLUE):addToManager()
    if self.polygon:getIsPosInside(self.pointX, self.pointZ) then
        self.debugPoint:setColor(Color.PRESETS.GREEN)
    else
        self.debugPoint:setColor(Color.PRESETS.RED)
    end
    self.debugCircle:createWithWorldPos(self.pointX, 0.03, self.pointZ, (math.abs((MathUtil.randomFloat(0, vMaxX * 0.9))))):addToManager()
    if self.polygon:getIsCircleIntersecting(self.pointX, self.pointZ, radius) then
        self.debugCircle:setColor(Color.PRESETS.GREEN)
    else
        self.debugCircle:setColor(Color.PRESETS.RED)
    end
    if self.polygon:getIsCircleInside(self.pointX, self.pointZ, radius) then
        DebugText.new():createWithWorldPos(self.pointX + 0.1, 0, self.pointZ, "inside"):addToManager()
    end
    local x2 = MathUtil.randomFloat(0, vMaxX * 2)
    local i = MathUtil.randomFloat(0, vMaxX * 2)
    local x2 = MathUtil.randomFloat(0, vMaxX * 2)
    local z2 = MathUtil.randomFloat(0, vMaxX * 2)
    DebugLine.new():createWithStartAndEndPos(x2, 0.03, i, x2, 0.03, z2):setColor(self.polygon:getIsLineSegmentIntersecting(x2, i, x2, z2) and Color.PRESETS.RED or Color.PRESETS.GREEN):addToManager()
end
function TestPolygon.update(dt)
    if g_updateLoopIndex % 300 == 0 then
        TestPolygon.generatePolygon()
    end
end
function TestPolygon.draw()
    g_debugManager:drawPreUI()
    g_debugManager:drawPostUI()
end
function TestPolygon.mouseEvent(posX, posY, isDown, isUp, button) end
function TestPolygon.keyEvent(unicode, sym, modifier, isDown) end