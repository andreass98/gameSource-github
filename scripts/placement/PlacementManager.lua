PlacementManager = {}
PlacementManager.TEST_STEP_SIZE = 1
PlacementManager.ASYNC_NUM_OVERLAPS_PER_TICK = 4
local PlacementManager_mt = Class(PlacementManager)
function PlacementManager.new(customMt)
    -- upvalues: (copy) PlacementManager_mt
    local self = setmetatable({}, customMt or PlacementManager_mt)
    self.getPlaceQueue = {}
    return self
end
function PlacementManager:delete()
    g_currentMission:removeUpdateable(self)
end
function PlacementManager:getPlaceAsync(places, reqSpace, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
    local task = FindPlaceTask.new(places, reqSpace, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
    table.insert(self.getPlaceQueue, task)
    g_currentMission:addUpdateable(self)
end
function PlacementManager:update()
    if #self.getPlaceQueue > 0 then
        for _ = 1, PlacementManager.ASYNC_NUM_OVERLAPS_PER_TICK do
            self.spaceIsFree = false
            if self.getPlaceQueue[1]:runStep() then
                table.remove(self.getPlaceQueue, 1)
                return
            end
        end
    else
        g_currentMission:removeUpdateable(self)
    end
end
function PlacementManager:consoleCommandTogglePlacementDebug()
    PlacementManager.debugEnabled = not PlacementManager.debugEnabled
    if not PlacementManager.debugEnabled then
        g_debugManager:removeGroup("PlacementManager")
    end
    return "PlacementManager debug = " .. tostring(PlacementManager.debugEnabled)
end