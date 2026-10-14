CableCar = {}
local CableCar_mt = Class(CableCar)
function CableCar.onCreate(_, id)
    g_currentMission:addUpdateable(CableCar.new(id))
end
function CableCar.new(id)
    -- upvalues: (copy) CableCar_mt
    local numCableCars = CableCar_mt
    local self = setmetatable({}, numCableCars)
    self.nurbsId = getChildAt(id, 0)
    self.cableCarIds = {}
    local numCableCars = self.cableCarIds
    table.insert(numCableCars, getChildAt(id, 1))
    self.times = {}
    local numCableCars = self.times
    table.insert(numCableCars, 0)
    self.truckIds = {}
    local numCableCars = self.truckIds
    table.insert(numCableCars, getChildAt(getChildAt(id, 1), 0))
    local length = getSplineLength(self.nurbsId)
    self.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 3.6
    local numCableCars = Utils.getNoNil(getUserAttribute(id, "numCableCars"), 1)
    local i = 2
    for i = i, numCableCars do
        local cableCarId = clone(self.cableCarIds[1], false, true)
        link(id, cableCarId)
        table.insert(self.cableCarIds, cableCarId)
        table.insert(self.times, 1 / numCableCars * (i - 1))
        table.insert(self.truckIds, getChildAt(cableCarId, 0))
    end
    if length ~= 0 then
        self.timeScale = self.timeScale / length
    end
    return self
end
function CableCar:delete() end
function CableCar:update(dt)
    local i = 1
    for i = i, #self.cableCarIds do
        self.times[i] = self.times[i] - 0.001 * dt * self.timeScale
        if self.times[i] < 0 then
            self.times[i] = self.times[i] + 1
        end
        if self.times[i] > 1 then
            self.times[i] = self.times[i] - 1
        end
        local x, y, z = getSplinePosition(self.nurbsId, self.times[i])
        local dx, dy, dz = getSplineDirection(self.nurbsId, self.times[i])
        setTranslation(self.cableCarIds[i], x, y, z)
        setDirection(self.cableCarIds[i], dx, 0, dz, 0, 1, 0)
        local _, dy1, dz1 = worldDirectionToLocal(self.cableCarIds[i], dx, dy, dz)
        setDirection(self.truckIds[i], 0, dy1, dz1, 0, 1, 0)
    end
end