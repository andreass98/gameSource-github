FindPlaceTask = {}
FindPlaceTask.SAFE_OFFSET = 0.05
FindPlaceTask.DEFAULT_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
local FindPlaceTask_mt = Class(FindPlaceTask)
function FindPlaceTask.new(places, size, callback, callbackTarget, filterFunction, yOffset, zOffset, useTerrainHeight)
    -- upvalues: (copy) FindPlaceTask_mt
    local self = setmetatable({}, FindPlaceTask_mt)
    self.places = places
    self.size = size
    self.halfWidth = size.width / 2
    self.halfLength = size.length / 2
    self.halfHeight = size.height / 2
    self.callback = callback
    self.callbackTarget = callbackTarget
    self.filterFunction = filterFunction
    self.yOffset = yOffset
    self.zOffset = zOffset
    self.useTerrainHeight = useTerrainHeight
    self.curPlaceIndex = 1
    self.currentPlace = nil
    self.currentPositionOffset = 0
    self.spaceIsFree = false
    self.noMoreSpaces = false
    return self
end
function FindPlaceTask:runStep()
    local isFinished = false
    self.spaceIsFree = false
    local pos = self:getNextPosition()
    if pos then
        self.spaceIsFree = true
        overlapBox(pos.overlapX, pos.overlapY, pos.overlapZ, pos.xRot, pos.yRot, pos.zRot, self.halfWidth, self.halfHeight, self.halfLength, "overlapBoxCallbackFuncFindPlace", self, FindPlaceTask.DEFAULT_COLLISION_MASK, true, true, true, true)
    else
        self.noMoreSpaces = true
    end
    if self.spaceIsFree or self.noMoreSpaces then
        self.callback(self.callbackTarget, pos)
        isFinished = true
    end
    return isFinished
end
function FindPlaceTask:overlapBoxCallbackFuncFindPlace(node)
    if node ~= 0 and (node ~= g_terrainNode and not getHasTrigger(node)) then
        self.spaceIsFree = false
        return false
    end
end
function FindPlaceTask:getPlaceFulfillsSizeRequirements()
    return self.size.width <= self.currentPlace.maxWidth and (self.size.length <= self.currentPlace.maxLength and self.size.height <= self.currentPlace.maxHeight)
end
function FindPlaceTask:getNextPosition()
    if self.currentPlace or self:nextPlace() then
        local currentPlace = self.currentPlace
        local widthMax, lengthMax = MathUtil.vector2Rotate(self.halfLength, self.halfWidth, currentPlace.palletRotationOffset)
        local neededOffset = math.max(widthMax, lengthMax) + (self.safeOffset or FindPlaceTask.SAFE_OFFSET)
        if self.currentPositionOffset == 0 then
            self.currentPositionOffset = neededOffset
        else
            self.currentPositionOffset = self.currentPositionOffset + neededOffset * 2
        end
        if self.currentPositionOffset >= currentPlace.width - neededOffset then
            if not self:nextPlace() then
                return
            end
            local dirX, dirY = MathUtil.vector2Rotate(self.halfLength, self.halfWidth, self.currentPlace.palletRotationOffset)
            self.currentPositionOffset = math.max(dirX, dirY) + (self.safeOffset or FindPlaceTask.SAFE_OFFSET)
        end
        local dirX = currentPlace.dirX
        local dirY = currentPlace.dirY
        local dirZ = currentPlace.dirZ
        local normX = currentPlace.dirPerpX
        local normY = currentPlace.dirPerpY
        local normZ = currentPlace.dirPerpZ
        local upX, upY, upZ = MathUtil.crossProduct(normX, normY, normZ, dirX, dirY, dirZ)
        local yOffset = self.yOffset or 0
        local yOffsetOverlap = self.halfHeight + yOffset
        local zOffset = self.currentPositionOffset
        local xRot, yRot, zRot = localRotationToWorld(self.currentPlace.startNode, 0, self.currentPlace.palletRotationOffset, 0)
        return {
            ["x"] = self.currentPlace.startX + normX * 0 + upX * yOffset + dirX * zOffset,
            ["y"] = self.currentPlace.startY + normY * 0 + upY * yOffset + dirY * zOffset,
            ["z"] = self.currentPlace.startZ + normZ * 0 + upZ * yOffset + dirZ * zOffset,
            ["overlapX"] = self.currentPlace.startX + normX * 0 + upX * yOffsetOverlap + dirX * zOffset,
            ["overlapY"] = self.currentPlace.startY + normY * 0 + upY * yOffsetOverlap + dirY * zOffset,
            ["overlapZ"] = self.currentPlace.startZ + normZ * 0 + upZ * yOffsetOverlap + dirZ * zOffset,
            ["xRot"] = xRot,
            ["yRot"] = yRot,
            ["zRot"] = zRot
        }
    end
    if PlacementManager ~= nil and PlacementManager.debugEnabled then
        Logging.devWarning("FindPlaceTask: no place available for requested size w=%.2f:, l=%.2f:, h=%.2f:", self.size.width, self.size.length, self.size.height)
    end
end
function FindPlaceTask:nextPlace()
    self.currentPositionOffset = 0
    while true do
        self.currentPlace = self.places[self.curPlaceIndex]
        if not self.currentPlace then
            break
        end
        if self:getPlaceFulfillsSizeRequirements() then
            self.curPlaceIndex = self.curPlaceIndex + 1
            return true
        end
        self.curPlaceIndex = self.curPlaceIndex + 1
    end
    return false
end