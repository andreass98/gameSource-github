SimParticleSystem = {}
local SimParticleSystem_mt = Class(SimParticleSystem)
function SimParticleSystem.onCreate(_, id)
    g_currentMission:addNonUpdateable(SimParticleSystem.new(id))
end
function SimParticleSystem.new(name)
    -- upvalues: (copy) SimParticleSystem_mt
    local geometry = SimParticleSystem_mt
    local self = setmetatable({}, geometry)
    self.id = name
    local geometry
    if getHasClassId(self.id, ClassIds.SHAPE) then
        geometry = getGeometry(self.id)
        if geometry == 0 then
            geometry = nil
        elseif not getHasClassId(geometry, ClassIds.PRECIPITATION) then
            geometry = particleSystem
        end
    else
        geometry = particleSystem
    end
    if geometry ~= nil then
        local geometry = getParticleSystemLifespan(geometry)
        addParticleSystemSimulationTime(geometry, geometry)
    end
    return self
end
function SimParticleSystem:delete() end