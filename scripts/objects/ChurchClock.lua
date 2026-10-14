ChurchClock = {}
local ChurchClock_mt = Class(ChurchClock)
function ChurchClock.onCreate(_, node)
    if g_currentMission.isLoadingMap then
        g_currentMission:addNonUpdateable(ChurchClock.new(node))
    else
        Logging.i3dWarning(node, "ChurchClock:onCreate() can only be used within the map itself, not placeables")
    end
end
function ChurchClock.new(node)
    -- upvalues: (copy) ChurchClock_mt
    local self = setmetatable({}, ChurchClock_mt)
    self.clocks = {}
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local clockNode = getChildAt(node, i)
        if clockNode ~= nil then
            local shortHand = getChildAt(clockNode, 0)
            local longHand = getChildAt(clockNode, 1)
            if shortHand ~= nil and longHand ~= nil then
                table.insert(self.clocks, {
                    ["shortHand"] = shortHand,
                    ["longHand"] = longHand
                })
            end
        end
    end
    self.hasClocks = #self.clocks > 0
    if self.hasClocks then
        g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
    end
    return self
end
function ChurchClock:delete()
    g_messageCenter:unsubscribeAll(self)
end
function ChurchClock:minuteChanged()
    if self.hasClocks then
        for _, c in pairs(self.clocks) do
            setRotation(c.shortHand, 0, 0, -(6.283185307179586 * (g_currentMission.environment.dayTime / 43200000)))
            setRotation(c.longHand, 0, 0, -(6.283185307179586 * (g_currentMission.environment.dayTime / 3600000)))
        end
    end
end