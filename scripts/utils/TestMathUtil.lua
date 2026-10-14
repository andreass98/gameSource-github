TestMathUtil = {}
function TestMathUtil.init()
    local self = TestMathUtil
    setEnablePostFx(false)
    self.camera = createCamera("Test", 1.2217304763960306, 0.001, 1000)
    g_cameraManager:addCamera(self.camera, nil, false)
    link(getRootNode(), self.camera)
    g_cameraManager:setActiveCamera(self.camera)
    setTranslation(self.camera, 0, 10, 0)
    setRotation(self.camera, -1.5707963267948966, -3.141592653589793, 0)
    self.generateLines()
end
function TestMathUtil.generateLines()
    local self = TestMathUtil
    g_debugManager:removeGroup("default")
    TestMathUtil.addLinesToDisplay(5, 4, 5, 5, 5, 5, 6, 6, "startEndTouching")
    TestMathUtil.addLinesToDisplay(8, 4, 9, 5, 9, 5, 10, 6, "startEndTouchingCollinear")
    TestMathUtil.addLinesToDisplay(1, 4, 3, 6, 2, 5, 3, 6, "partialCollinearOverlap")
    TestMathUtil.addLinesToDisplay(-2, 4, 0, 6, -1, 5, -0.5, 5.5, "partialCollinearOverlap 2")
    TestMathUtil.addLinesToDisplay(8, 0, 7, 2, 7, 0.5, 9, 1, "overlap")
    TestMathUtil.addLinesToDisplay(5, 0, 6, 1, 5.5, 0.5, 4, 2, "endPointOverlap")
    TestMathUtil.addLinesToDisplay(0, 0, 2, 1, 2, 1, 0, 0, "fullyOverlapping")
    TestMathUtil.addLinesToDisplay(-3, 0, -1, 1, -1, 1, -3, 0, "fullyOverlapping flipped")
    TestMathUtil.addLinesToDisplay(-6, 0, -5, 1, -6.5, 0, -5.5, 1, "collinear")
    TestMathUtil.addLinesToDisplay(-9, 0, -8, 1, -8.7, 0.5, -10, 0.5, "disjunct")
end
function TestMathUtil.addLinesToDisplay(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2, label)
    DebugLine.new():createWithStartAndEndPos(ax1, 0, az1, ax2, 0, az2, false, false):setText("A"):setColor(Color.PRESETS.TURQUOISE):addToManager()
    DebugPoint.new():createWithWorldPos(ax1, 0, az1):setColor(Color.PRESETS.TURQUOISE):addToManager()
    DebugPoint.new():createWithWorldPos(ax2, 0, az2):setColor(Color.PRESETS.TURQUOISE):addToManager()
    DebugLine.new():createWithStartAndEndPos(bx1, 0, bz1, bx2, 0, bz2, false, false):setText("B"):setColor(Color.PRESETS.YELLOW):addToManager()
    DebugPoint.new():createWithWorldPos(bx1, 0, bz1):setColor(Color.PRESETS.YELLOW):addToManager()
    DebugPoint.new():createWithWorldPos(bx2, 0, bz2):setColor(Color.PRESETS.YELLOW):addToManager()
    local intersecting = MathUtil.getAreLineSegmentsIntersecting(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
    local intersectingExcludeStartEnd = MathUtil.getAreLineSegmentsIntersecting(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2, true)
    local cx = (math.max(ax1, ax2, bx1, bx2) + math.min(ax1, ax2, bx1, bx2)) / 2
    local z = math.min(az1, az2, bz1, bz2) - 0.25
    DebugText.new():createWithWorldPos(cx, 0, z + 0.15, label, 0.015):addToManager()
    DebugText.new():createWithWorldPos(cx, 0, z, string.format("intersecting %s", intersecting), 0.01):setColor(intersecting and Color.PRESETS.RED or Color.PRESETS.GREEN):addToManager()
    DebugText.new():createWithWorldPos(cx, 0, z - 0.12, string.format("intersecting startEnd %s", intersectingExcludeStartEnd), 0.01):setColor(intersectingExcludeStartEnd and Color.PRESETS.RED or Color.PRESETS.GREEN):addToManager()
end
function TestMathUtil.update(dt)
    if g_updateLoopIndex % 100 == 0 then
        TestMathUtil.generateLines()
    end
end
function TestMathUtil.draw()
    g_debugManager:drawPreUI()
    g_debugManager:drawPostUI()
end
function TestMathUtil.mouseEvent(posX, posY, isDown, isUp, button) end
function TestMathUtil.keyEvent(unicode, sym, modifier, isDown) end