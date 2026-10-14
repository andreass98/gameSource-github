FerryStateWaiting = {}
local FerryStateWaiting_mt = Class(FerryStateWaiting, FerryState)
function FerryStateWaiting.new(ferry, customMt)
    -- upvalues: (copy) FerryStateWaiting_mt
    local self = FerryState.new(ferry, customMt or FerryStateWaiting_mt)
    self.isFinished = false
    return self
end
function FerryStateWaiting:isDone()
    if FerryStateWaiting:superClass().isDone(self) then
        return self.isFinished
    else
        return false
    end
end
function FerryStateWaiting:deactivate()
    FerryStateWaiting:superClass().deactivate(self)
    self.isFinished = false
end
function FerryStateWaiting:getCanFinishState()
    return true
end
function FerryStateWaiting:finish()
    self.isFinished = true
end