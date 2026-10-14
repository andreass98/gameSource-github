TestI3DManager = {}
function TestI3DManager.init()
    local self = TestI3DManager
    self.file = "data/vehicles/fendt/vario900/vario900.i3d"
    self.sharedLoadRequestIds = {}
end
function TestI3DManager.update(dt) end
function TestI3DManager.draw()
    g_i3DManager:drawDebug()
end
function TestI3DManager.mouseEvent(posX, posY, isDown, isUp, button) end
function TestI3DManager.keyEvent(_, sym, _, isDown)
    if not isDown then
        if sym == Input.KEY_m then
            local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(TestI3DManager.file, false, false, TestI3DManager.finishedLoading, TestI3DManager, {
                ["file"] = TestI3DManager.file
            })
            table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
            return
        end
        if sym == Input.KEY_n then
            local sharedLoadRequestId = table.remove(self.sharedLoadRequestIds, 1)
            if sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
                return
            end
        elseif sym == Input.KEY_q then
            restartApplication(false, "")
        end
    end
end
function TestI3DManager.finishedLoading(_, nodeId, _, _)
    log("loaded", getName(nodeId))
    delete(nodeId)
end