VectorTest = {}
function VectorTest.test_eulerToDirection()
    local testNode, directionY, directionZ = MathUtil.eulerToDirection(0, 1.5707963267948966)
    Assert.areRoughlyEqual(testNode, 0)
    Assert.areRoughlyEqual(directionY, -1)
    Assert.areRoughlyEqual(directionZ, 0)
    local testNode, directionY, directionZ = MathUtil.eulerToDirection(0, -1.5707963267948966)
    Assert.areRoughlyEqual(testNode, 0)
    Assert.areRoughlyEqual(directionY, 1)
    Assert.areRoughlyEqual(directionZ, 0)
    local testNode, directionY, directionZ = MathUtil.eulerToDirection(1.5707963267948966, 0)
    Assert.areRoughlyEqual(testNode, 1)
    Assert.areRoughlyEqual(directionY, 0)
    Assert.areRoughlyEqual(directionZ, 0)
    local testNode, directionY, directionZ = MathUtil.eulerToDirection(-1.5707963267948966, 0)
    Assert.areRoughlyEqual(testNode, -1)
    Assert.areRoughlyEqual(directionY, 0)
    Assert.areRoughlyEqual(directionZ, 0)
    local testNode, directionY, directionZ = MathUtil.eulerToDirection(0, 0)
    Assert.areRoughlyEqual(testNode, 0)
    Assert.areRoughlyEqual(directionY, 0)
    Assert.areRoughlyEqual(directionZ, 1)
    local testNode, directionY, directionZ = MathUtil.eulerToDirection(3.141592653589793, 0)
    Assert.areRoughlyEqual(testNode, 0)
    Assert.areRoughlyEqual(directionY, 0)
    Assert.areRoughlyEqual(directionZ, -1)
    local testNode = createTransformGroup("test")
    local pitch = -3.141592653589793
    for pitch = pitch, 3.141592653589793, 0.2617993877991494 do
        local yaw = -3.141592653589793
        for yaw = yaw, 3.141592653589793, 0.2617993877991494 do
            setWorldRotation(testNode, pitch, yaw, 0)
            local nodeDirectionX, nodeDirectionY, nodeDirectionZ = MathUtil.eulerToDirection(yaw, pitch)
            local nodeDirectionX, nodeDirectionY, nodeDirectionZ = localDirectionToWorld(testNode, 0, 0, 1)
            Assert.areRoughlyEqual(nodeDirectionX, nodeDirectionX)
            Assert.areRoughlyEqual(nodeDirectionY, nodeDirectionY)
            Assert.areRoughlyEqual(nodeDirectionZ, nodeDirectionZ)
        end
    end
    delete(testNode)
end