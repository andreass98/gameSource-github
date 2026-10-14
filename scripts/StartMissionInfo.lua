StartMissionInfo = {}
local StartMissionInfo_mt = Class(StartMissionInfo)
function StartMissionInfo.new(subclass_mt)
    -- upvalues: (copy) StartMissionInfo_mt
    local self = setmetatable({}, subclass_mt or StartMissionInfo_mt)
    self:reset()
    return self
end
function StartMissionInfo:reset()
    self.isMultiplayer = false
    self.createGame = false
    self.canStart = false
    self.mapId = "MapUS"
    self.economicDifficulty = EconomicDifficulty.EASY
    self.initialMoney = 100000
    self.initialLoan = 0
    self.hasStartFarm = true
    self.startWithGuidedTour = true
end