FerryStateArriveDock = {}
local FerryStateArriveDock_mt = Class(FerryStateArriveDock, FerryState)
function FerryStateArriveDock.new(ferry, customMt)
    -- upvalues: (copy) FerryStateArriveDock_mt
    return FerryState.new(ferry, customMt or FerryStateArriveDock_mt)
end
function FerryStateArriveDock:deactivate()
    FerryStateArriveDock:superClass().deactivate(self)
    self.ferry:unmountObjects()
end