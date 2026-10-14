TestDebugElements = {}
function TestDebugElements.init()
    local self = TestDebugElements
    setEnablePostFx(false)
    executeConsoleCommand("enableNoteRendering true", true)
    self.cameraRotCenter = createTransformGroup("cameraRotCenter")
    link(getRootNode(), self.cameraRotCenter)
    self.camera = createCamera("Test", 1.2217304763960306, 0.001, 1000)
    g_cameraManager:addCamera(self.camera, nil, false)
    link(self.cameraRotCenter, self.camera)
    g_cameraManager:setActiveCamera(self.camera)
    setTranslation(self.camera, 0, 5, 10)
    setRotation(self.camera, -0.5235987755982988, 0, 0)
    self.bitVectorMap = createBitVectorMap("bitVectorMapDebugElementsTest")
    loadBitVectorMapNew(self.bitVectorMap, 16, 16, 2, false)
    self.debugBitVectorMap = DebugBitVectorMap.newSimple(20, 1, false, 0.2)
    self.debugBitVectorMap:createWithCustomFunc(function(_, startWorldX, startWorldZ, _, _, _, _)
        -- upvalues: (copy) self
        if startWorldX >= 0 and startWorldZ >= 0 then
            return getBitVectorMapPoint(self.bitVectorMap, startWorldX, startWorldZ, 0, 2)
        end
    end)
    g_debugManager:addElement(self.debugBitVectorMap)
    self.node = createTransformGroup("debugCubeTest")
    link(getRootNode(), self.node)
    setRotation(self.node, 0, 3.839724354387525, 0)
    self.debugCube = DebugBox.new():setDrawFaces(true):setColorRGBA(0, 0, 1):setText("CubeInstance")
    g_debugManager:addElement(self.debugCube)
    self.node2 = createTransformGroup("debugCubeTest")
    link(getRootNode(), self.node2)
    setTranslation(self.node2, -2, 0, 0)
    setRotation(self.node2, 0, 3.839724354387525, 0)
    self.node3 = createTransformGroup("debugCubeTest")
    link(getRootNode(), self.node3)
    setTranslation(self.node3, -4, 2, 0)
    self.node4 = createTransformGroup("debugCubeTest")
    link(getRootNode(), self.node4)
    setTranslation(self.node4, 0, 2, 0)
    self.node5 = createTransformGroup("debugFlagTest")
    link(getRootNode(), self.node5)
    setTranslation(self.node5, 5, -1, -4)
    self.debugPath = DebugPath.newSimple(DebugUtil.getDebugColor(math.random(10)), false, nil, false):setText("debugPath instance")
    local i = 1
    for i = i, 10 do
        self.debugPath:addPoint(i / 2, math.random(), -i * 2 + math.random())
    end
    g_debugManager:addElement(self.debugPath)
    g_debugManager:addElement(DebugText.new():createWithNode(self.node4, "DebugText", 0.02))
    g_debugManager:addElement(DebugLine.new():createWithStartAndEndPos(8, -2, 3, 15, 4, 5):setColors(Color.PRESETS.RED, Color.PRESETS.BLUE))
    self.debugFunc = DebugFunction.new(function(instance, dt)
        instance.dt = instance.dt + dt
    end, function(instance)
        renderText(0.9, 0.14, 0.02, "DebugFunc")
        renderText(0.9, 0.11, 0.02, (tostring(getTime())))
        renderText(0.9, 0.08, 0.02, (tostring(g_updateLoopIndex)))
        renderText(0.9, 0.05, 0.02, string.format("%.5f", instance.dt))
        setNoteNodeText(instance.noteNode, string.format("%d", instance.dt / 1000))
    end, function(instance)
        instance.dt = 0
        instance.noteNode = createNoteNode(nil, "noteNode bla bla", 0, 0.3, 0, true)
        link(getRootNode(), instance.noteNode)
        setTranslation(instance.noteNode, 0, 3, 0)
    end, function(instance)
        delete(instance.noteNode)
    end)
    g_debugManager:addElement(self.debugFunc)
    self.spline = createSplineFromEditPoints(getRootNode(), {
        -6,
        0,
        5,
        5,
        1,
        5,
        5,
        1,
        -5,
        -5,
        0,
        -4.9
    }, false, false)
    setName(self.spline, "spline, instance")
    self.debugSpline = DebugSpline.new():createWithNode(self.spline, nil, 10, true)
    g_debugManager:addElement(self.debugSpline)
    self.splineStatic = createSplineFromEditPoints(getRootNode(), {
        -8,
        0,
        5,
        -12,
        3,
        7,
        -15,
        0,
        10
    }, false, true)
    setName(self.splineStatic, "spline, static")
    self.splineBVTest = createSplineFromEditPoints(getRootNode(), {
        -7,
        0,
        2,
        -5,
        0,
        2
    }, false, false)
    g_debugManager:addElement(DebugSphere.new():createShapeBoundingSphere(self.splineBVTest))
    g_debugManager:addElement(DebugPlane.newSimple(false, false, Color.PRESETS.LIMEGREEN, true):createWithPositions(-3, 0, 2, -2, 0.5, 3, -3, 0.5, 4))
    g_debugManager:addElement(DebugPlane.newSimple(false, false, Color.PRESETS.ORANGE, true):createWithPositionsOffset(-4, -2, 2, 2, 0, 1, 1, 0, 2))
    self.node6 = createTransformGroup("debugFlagTest2")
    link(getRootNode(), self.node6)
    setTranslation(self.node6, 7, -1, 8)
    setRotation(self.node6, 0, math.random(0, 6.283185307179586), 0)
    g_debugManager:addElement(DebugFlag.new():createWithNode(self.node6))
    g_debugManager:addElement(DebugGizmo.new():createWithNode(self.node6))
    self.debugCylinder = DebugCylinder.new():createWithWorldPos(4, 0, -3, 0.5, 2, Axis.Y):setColorRGBA(1, 1, 0):setText("CylinderInstance")
    g_debugManager:addElement(self.debugCylinder)
    self.debugPyramid = DebugPyramid.new():setColorRGBA(1, 0, 1):setText("PyramidInstance"):setDrawFaces(true)
    local i = self.debugPyramid
    self.debugPyramid.x = -2
    self.debugPyramid.y = 1
    i.z = 6
    g_debugManager:addElement(self.debugPyramid)
    self.debugCamera = DebugCamera.new():setColorRGBA(0, 1, 1):setText("CameraInstance")
    local i = self.debugCamera
    self.debugCamera.x = 8
    self.debugCamera.y = 1
    i.z = 0
    g_debugManager:addElement(self.debugCamera)
end
function TestDebugElements.update(dt)
    local self = TestDebugElements
    g_debugManager:update(dt)
    rotate(self.cameraRotCenter, 0, 0.003, 0)
    self.debugCube:createWithNode(self.node)
    rotate(self.node, 0.004, 0.005, 0.006)
    rotate(self.node5, 0, -0.01, 0)
    if math.random() < 0.1 then
        self.debugCube:setColor(DebugUtil.getDebugColor(math.random(10)))
    end
    if g_updateLoopIndex % 40 == 0 then
        for i = 0, 5 do
            local sx = math.random(0, 8) * 2
            local sz = math.random(0, 8) * 2
            local value = math.random(0, 2)
            setBitVectorMapParallelogram(self.bitVectorMap, sx, sz, 1.5, 0, 0, 1.5, 0, 2, value)
        end
    end
    local sx = 1.1 + math.sin(g_time / 1000)
    self.debugCube:setSize(1, sx, 1.1 + math.cos((g_time + 500) / 1000))
    self.debugPath:setClipDistance(6 + (1 + math.sin(g_time / 1000) / 2) * 20)
    if math.random() < 0.005 then
        self.debugPath:clear()
        local i = 1
        for i = i, 10 do
            self.debugPath:addPoint(i / 2, math.random(), -i * 2 + math.random())
        end
    end
    if self.debugFunc ~= nil and g_time > 30000 then
        g_debugManager:removeElement(self.debugFunc)
        self.debugFunc = nil
    end
end
function TestDebugElements.draw()
    local self = TestDebugElements
    g_debugManager:drawPreUI()
    DebugBox.renderAtPosition(-5.5, -2, -1, 0, 1, 0, 0, 0, 1, 0.5, 2, 0.2, Color.PRESETS.RED, false, "staticCall 1", nil, false)
    DebugBox.renderAtPosition(3.5, 1, 1, 0, 1, 0, 0, 0, 1, 0.5, 2, 0.2, Color.PRESETS.GREEN, false, "staticCall\n2", nil, true)
    DebugBox.renderWithStartAndEndNode(self.node2, self.node4, Color.PRESETS.LIGHTGRAY, false, "BoxStartAndEndNode", nil, true)
    DebugCircle.renderAtPosition(1, -2, 2, 3, Color.PRESETS.DARKORANGE, nil, nil, nil, true, "a Kreis, Hann")
    DebugCircle.renderAtPosition(-4, -3, 4, 2, Color.PRESETS.OLIVE, nil, nil, nil, false)
    DebugCircle.renderAtPosition(-5, -3, 0, 1.5, Color.PRESETS.BLUE)
    DebugPlane.renderWithPositions(-5, 0, -2, -7, 0, -3, -5, 0, -5, Color.PRESETS.DARKMAGENTA, false, true, true, false, "plane")
    self.debugPathPoints = self.debugPathPoints or {
        { -3, -2, 0 },
        { 3, -1, 1 },
        { 5, -2, 0 },
        { 2, -2, 0 },
        { 2, -2, -20 },
        { 3, 5, -22 }
    }
    DebugPath.renderPath(self.debugPathPoints, nil, false, nil, false, 12)
    DebugFlag.renderAtPosition(-7, -2, -8, 0.5, 0, Color.PRESETS.LIGHTGREEN, "Flag\nText")
    DebugPoint.renderAtPosition(5, 3, 4, Color.PRESETS.DARKRED, true, "DebugPoint")
    DebugLine.renderBetweenNodes(self.node2, self.node3, Color.PRESETS.MAGENTA, false, "debugLine\nnodeToNode")
    self.debugInfoTableData = self.debugInfoTableData or {
        {
            ["title"] = "Title 1",
            ["content"] = {
                {
                    ["name"] = "T1V1",
                    ["value"] = 0.5
                }
            }
        },
        {
            ["title"] = "Title 2",
            ["content"] = {
                {
                    ["name"] = "T2V1",
                    ["value"] = "bla bla bla"
                },
                {
                    ["name"] = "T2V2 long name",
                    ["value"] = "Hansi with custom color",
                    ["color"] = Color.new(1, 0, 0, 0.1)
                },
                {
                    ["name"] = "T2V3 size factor",
                    ["value"] = "Jochen with custom size",
                    ["sizeFactor"] = 0.7
                }
            }
        }
    }
    DebugInfoTable.renderAtPosition(-7, 1, -3, self.debugInfoTableData, nil, nil, nil, 0.3, Color.PRESETS.INDIGO)
    DebugSphere.renderAtPosition(-5, 0, 5, 1.5, Color.PRESETS.GREEN, nil, nil, nil, "sphere")
    DebugGizmo.renderAtPosition(2, 3, 4, 0, 1, 0, 0.5, 0, 0.5, "Gizmo static", false, nil, nil, Color.PRESETS.CYAN, nil)
    DebugSpline.renderForNode(self.splineStatic, Color.PRESETS.BROWN, "static spline", 15, true)
    DebugFlag.renderAtNode(self.node5, nil, nil, Color.PRESETS.FIREBRICK, "flag at node")
    if self.debugPolygonVertices == nil then
        self.debugPolygonVertices = {
            1,
            0,
            0,
            0.5,
            0,
            -0.8660254037844386,
            -0.5,
            0,
            -0.8660254037844386,
            -1,
            0,
            0,
            -0.5,
            0,
            0.8660254037844386,
            0.5,
            0,
            0.8660254037844386
        }
        local i = 1
        for i = i, #self.debugPolygonVertices, 3 do
            self.debugPolygonVertices[i] = self.debugPolygonVertices[i] - 3
            self.debugPolygonVertices[i + 2] = self.debugPolygonVertices[i + 2] - 4
        end
    end
    DebugPolygon.renderWithPositions(self.debugPolygonVertices, Color.PRESETS.LAVENDER, true)
    DebugCylinder.renderAtPosition(-3, -2, -7, 0.5, 2, Axis.Y, Color.PRESETS.OLIVE, nil, false, false, "CylinderStatic")
    DebugPyramid.renderAtPosition(6, -1, -5, 0, 1, 0, 0, 0, 1, 1, 1.5, 1, Color.PRESETS.LAVENDER, false, "Pyramid\nstatic", nil, true)
    DebugCamera.renderAtPosition(8, 3, -2, 0, 1, 0, 0, 0, 1, 1, 1, 1, Color.PRESETS.CYAN, false, "Camera\nstatic", nil, false)
    g_debugManager:drawPostUI()
end
function TestDebugElements.mouseEvent(posX, posY, isDown, isUp, button) end
function TestDebugElements.keyEvent(unicode, sym, modifier, isDown) end