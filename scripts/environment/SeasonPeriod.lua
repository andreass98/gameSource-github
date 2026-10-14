SeasonPeriod = {}
SeasonPeriod.EARLY_SPRING = 1
SeasonPeriod.MID_SPRING = 2
SeasonPeriod.LATE_SPRING = 3
SeasonPeriod.EARLY_SUMMER = 4
SeasonPeriod.MID_SUMMER = 5
SeasonPeriod.LATE_SUMMER = 6
SeasonPeriod.EARLY_AUTUMN = 7
SeasonPeriod.MID_AUTUMN = 8
SeasonPeriod.LATE_AUTUMN = 9
SeasonPeriod.EARLY_WINTER = 10
SeasonPeriod.MID_WINTER = 11
SeasonPeriod.LATE_WINTER = 12
Enum(SeasonPeriod)
function SeasonPeriod.getSeason(period)
    if SeasonPeriod.EARLY_SPRING <= period and period <= SeasonPeriod.LATE_SPRING then
        return Season.SPRING
    elseif SeasonPeriod.EARLY_SUMMER <= period and period <= SeasonPeriod.LATE_SUMMER then
        return Season.SUMMER
    elseif SeasonPeriod.EARLY_AUTUMN <= period and period <= SeasonPeriod.LATE_AUTUMN then
        return Season.AUTUMN
    elseif SeasonPeriod.EARLY_WINTER <= period and period <= SeasonPeriod.LATE_WINTER then
        return Season.WINTER
    else
        return nil
    end
end