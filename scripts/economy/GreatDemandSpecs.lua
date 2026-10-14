GreatDemandSpecs = {}
local GreatDemandSpecs_mt = Class(GreatDemandSpecs)
function GreatDemandSpecs.new(customMt)
    -- upvalues: (copy) GreatDemandSpecs_mt
    local self = setmetatable({}, customMt or GreatDemandSpecs_mt)
    self.sellStation = nil
    self.fillTypeIndex = 0
    self.demandMultiplier = 1
    self.demandStart = {
        ["day"] = 0,
        ["hour"] = 0
    }
    self.demandDuration = 0
    self.isRunning = false
    self.isValid = false
    return self
end
function GreatDemandSpecs.getIsDateEarlier(_, day1, hour1, day2, hour2)
    return day1 < day2 or day1 == day2 and hour1 < hour2
end
function GreatDemandSpecs:setUpRandomDemand(weighted, greatDemands, mission)
    self.isRunning = false
    self.isValid = false
    self.fillTypeIndex = 0
    self.demandMultiplier = math.random(11, 14) / 10
    self.demandStart.day = mission.environment.currentMonotonicDay + math.random(2, 5)
    self.demandStart.hour = math.random(7, 18)
    self.demandDuration = math.random(1, 4) * 6
    for _, greatDemand in pairs(greatDemands) do
        if greatDemand ~= self and greatDemand.isValid then
            ({})[greatDemand.sellStation] = true
        end
    end
    local validUnloadingStations = {}
    for greatDemand, station in pairs(mission.storageSystem:getUnloadingStations()) do
        if station.supportsGreatDemand and (station.getSupportsGreatDemand ~= nil and (not station.isGreatDemandActive and blockedTipTrigger[station] == nil)) then
            table.insert(validUnloadingStations, station)
        end
    end
    if #validUnloadingStations > 0 then
        local tipTrigger = validUnloadingStations[math.random(1, #validUnloadingStations)]
        self.sellStation = tipTrigger
        local start = self.demandStart
        local greatDemand = (start.hour + self.demandDuration) / 24
        local _, greatDemand = math.modf(greatDemand)
        local greatDemand = greatDemand * 24
        if greatDemands ~= nil then
            for _, greatDemand in pairs(greatDemands) do
                if greatDemand ~= self and (greatDemand.isValid and self.sellStation == greatDemand.sellStation) then
                    local otherEndDayOffset, otherEndHour = math.modf((greatDemand.demandStart.hour + greatDemand.demandDuration) / 24)
                    if not (self:getIsDateEarlier(start.day + _, greatDemand, otherStart.day, otherStart.hour) or self:getIsDateEarlier(otherStart.day + otherEndDayOffset, otherEndHour * 24, start.day, start.hour)) then
                        ({})[greatDemand.fillTypeIndex] = true
                    end
                end
            end
        end
        local validFillTypes = {}
        for greatDemand, otherStart in pairs(tipTrigger.acceptedFillTypes) do
            if otherStart and (conflictingFillTypes[greatDemand] == nil and tipTrigger.fillTypeSupportsGreatDemand[greatDemand]) then
                table.insert(validFillTypes, greatDemand)
            end
        end
        if #validFillTypes > 0 then
            if weighted then
                local amountUberTotal = 0
                for otherStart, otherEndDayOffset in pairs(validFillTypes) do
                    amountUberTotal = amountUberTotal + g_fillTypeManager:getFillTypeByIndex(otherEndDayOffset).totalAmount
                end
                if amountUberTotal > 0 then
                    local inverseRatioTotal = 0
                    local _ = {}
                    for otherEndHour, otherEndDay in pairs(validFillTypes) do
                        local inverseRatio = g_fillTypeManager:getFillTypeByIndex(otherEndDay).totalAmount / amountUberTotal
                        local inverseRatio = 1 / math.max(inverseRatio, 1e-6)
                        table.insert(_, {
                            ["fillTypeIndex"] = otherEndDay,
                            ["inverseRatio"] = inverseRatio
                        })
                    end
                    local greatDemand = math.random()
                    for otherEndDay, fillType in pairs(_) do
                        greatDemand = greatDemand - fillType.inverseRatio / inverseRatioTotal
                        if greatDemand <= 0.0001 then
                            self.fillTypeIndex = fillType.fillTypeIndex
                            break
                        end
                    end
                end
            else
                self.fillTypeIndex = validFillTypes[math.random(1, #validFillTypes)]
            end
            if self.fillTypeIndex ~= 0 then
                self.isValid = true
            end
        end
    end
end