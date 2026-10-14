BalerStationary = {}
source("dataS/scripts/gui/hud/extensions/BalerStationaryHUDExtension.lua")
function BalerStationary.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Baler, specializations) and SpecializationUtil.hasSpecialization(BaleWrapper, specializations) and SpecializationUtil.hasSpecialization(FoldableSteps, specializations)
end
function BalerStationary.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BalerStationary)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BalerStationary)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BalerStationary)
end
function BalerStationary:onLoad()
    self.spec_balerStationary.hudExtension = BalerStationaryHUDExtension.new(self)
end
function BalerStationary:onDelete()
    local spec = self.spec_balerStationary
    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end
function BalerStationary:onDraw()
    local spec = self.spec_balerStationary
    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end