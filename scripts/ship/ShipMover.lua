ShipMover = {}
local Ship_mt = Class(ShipMover, Object)
InitStaticObjectClass(ShipMover, "ShipMover")
g_xmlManager:addInitSchemaFunction(function()
    OnCreateObjectSystem.xmlSchemaSavegame:register(XMLValueType.FLOAT, "onCreateLoadedObjects.object(?)#time", "Current spline time")
end)
function ShipMover.onCreate(_, node)
    local ship = ShipMover.new
    local ship = ship(g_server ~= nil, g_client ~= nil)
    if ship:load(node) then
        ship:register(true)
    else
        ship:delete()
    end
end
function ShipMover.new(isServer, isClient, customMt)
    -- upvalues: (copy) Ship_mt
    local self = Object.new(isServer, isClient, customMt or Ship_mt)
    self.dirtyFlag = self:getNextDirtyFlag()
    return self
end
function ShipMover:load(splineNode)
    if not I3DUtil.getIsSpline(splineNode) then
        Logging.warning("Given node \'%s\' is not a spline for ShipMover", getName(splineNode))
        return false
    end
    self.splineNode = splineNode
    self.currentSplineTime = 0
    self.currentSplineTimeSent = 0
    self.saveId = getName(splineNode)
    local maxSpeedMps = MathUtil.kmhToMps(getUserAttribute(splineNode, "speedKmh") or 5)
    local splineLength = getSplineLength(splineNode)
    self.deltaSplineTimePerMs = maxSpeedMps / splineLength / 1000
    self.ships = {}
    local i = 0
    for i = i, getNumOfChildren(splineNode) - 1 do
        local shipNode = getChildAt(splineNode, i)
        local x, y, z = getWorldTranslation(shipNode)
        local _, _, _, t = getClosestSplinePosition(splineNode, x, y, z, 1)
        local length = getUserAttribute(shipNode, "length") or 10
        table.insert(self.ships, {
            ["node"] = shipNode,
            ["offset"] = t,
            ["safetyOffset"] = 20 / splineLength,
            ["length"] = length,
            ["currentTime"] = t,
            ["currentTimeFront"] = t
        })
    end
    if self.isServer then
        self.dirtyFlag = self:getNextDirtyFlag()
        self.updateThreshold = 0.05 / splineLength
    else
        self.networkTimeInterpolator = InterpolationTime.new(1.2)
        self.networkSplineTimeInterpolator = InterpolatorSplineTime.new(0, true)
    end
    g_currentMission.shipSystem:addSpline(self.splineNode, self)
    g_currentMission.onCreateObjectSystem:add(self, true)
    return true
end
function ShipMover:delete()
    g_currentMission.shipSystem:removeSpline(self.splineNode, self)
    ShipMover:superClass().delete(self)
end
function ShipMover:loadFromXMLFile(xmlFile, key)
    local time = xmlFile:getValue(key .. "#time")
    if time ~= nil then
        self.currentSplineTime = time
        self.currentSplineTimeSent = time
        self:updatePosition()
    end
    return true
end
function ShipMover:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#time", self.currentSplineTime)
end
function ShipMover:readStream(streamId, connection, _)
    if connection:getIsServer() then
        self.currentSplineTime = streamReadFloat32(streamId)
        self.networkTimeInterpolator:reset()
    end
end
function ShipMover:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteFloat32(streamId, self.currentSplineTimeSent)
    end
end
function ShipMover:readUpdateStream(streamId, _, connection)
    ShipMover:superClass().readUpdateStream(self, streamId, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local time = streamReadFloat32(streamId)
        self.networkSplineTimeInterpolator:setTargetValue(time, 1)
        self.networkTimeInterpolator:startNewPhaseNetwork()
    end
end
function ShipMover:writeUpdateStream(streamId, connection, dirtyMask)
    ShipMover:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.dirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.currentSplineTimeSent)
        end
    end
end
function ShipMover:update(dt)
    ShipMover:superClass().update(self, dt)
    if self.isServer then
        self.currentSplineTime = (self.currentSplineTime + self.deltaSplineTimePerMs * dt) % 1
        if math.abs(self.currentSplineTime - self.currentSplineTimeSent) > self.updateThreshold then
            self.currentSplineTimeSent = self.currentSplineTime
            self:raiseDirtyFlags(self.dirtyFlag)
        end
        self:raiseActive()
    else
        self.networkTimeInterpolator:update(dt)
        local deltaTime = self.networkTimeInterpolator:getAlpha()
        self.currentSplineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(deltaTime)
        if self.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end
    self:updatePosition()
end
function ShipMover:updatePosition()
    for _, ship in ipairs(self.ships) do
        local node = ship.node
        local shipTime = (self.currentSplineTime + ship.offset) % 1
        local x, y, z = getSplinePosition(self.splineNode, shipTime)
        setWorldTranslation(node, x, y, z)
        local _, _, _, frontTime = getSplinePositionWithDistance(self.splineNode, shipTime, ship.length, true, 0.1)
        local xFront, yFront, zFront = getSplinePosition(self.splineNode, frontTime)
        local dirX = xFront - x
        local dirY = yFront - y
        local dirZ = zFront - z
        if MathUtil.vector3Length(dirX, dirY, dirZ) < 0.001 then
            dirX, dirY, dirZ = getSplineDirection(self.splineNode, shipTime)
        end
        setWorldDirection(node, dirX, dirY, dirZ, 0, 1, 0)
        ship.currentTime = shipTime
        ship.currentTimeFront = frontTime
    end
end
function ShipMover:getIsShipCrossingPoint(_, time, durationMs)
    for _, ship in ipairs(self.ships) do
        if time - self.deltaSplineTimePerMs * durationMs - ship.safetyOffset < ship.currentTimeFront and ship.currentTime < time + ship.safetyOffset then
            return true
        end
    end
    return false
end