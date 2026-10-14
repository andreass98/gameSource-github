PackedBale = {}
PackedBale.MAX_UNPACK_DISTANCE = 4
source("dataS/scripts/events/BaleUnpackEvent.lua")
local PackedBale_mt = Class(PackedBale, Bale)
InitStaticObjectClass(PackedBale, "PackedBale")
function PackedBale.new(isServer, isClient, customMt)
    -- upvalues: (copy) PackedBale_mt
    local self = Bale.new(isServer, isClient, customMt or PackedBale_mt)
    registerObjectClassName(self, "PackedBale")
    self.singleBaleNodes = {}
    self.packedBaleActivatable = PackedBaleActivatable.new(self)
    self.maxUnpackDistance = PackedBale.MAX_UNPACK_DISTANCE
    return self
end
function PackedBale:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self.packedBaleActivatable)
    PackedBale:superClass().delete(self)
end
function PackedBale:loadBaleAttributesFromXML(xmlFile)
    if not PackedBale:superClass().loadBaleAttributesFromXML(self, xmlFile) then
        return false
    end
    self.singleBaleFilename = xmlFile:getValue("bale.packedBale#singleBale")
    self.singleBaleFilename = Utils.getFilename(self.singleBaleFilename, self.baseDirectory)
    if self.singleBaleFilename == nil or not fileExists(self.singleBaleFilename) then
        Logging.xmlError(xmlFile, "Could not find single bale reference for bale (%s)", self.singleBaleFilename)
        return false
    end
    xmlFile:iterate("bale.packedBale.singleBale", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self
        local node = xmlFile:getValue(key .. "#node", nil, self.nodeId)
        if node ~= nil then
            table.insert(self.singleBaleNodes, node)
        end
    end)
    g_currentMission.activatableObjectsSystem:addActivatable(self.packedBaleActivatable)
    return true
end
function PackedBale:unpack(_)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.packedBaleActivatable)
    if self.isServer then
        local i = 1
        for i = i, #self.singleBaleNodes do
            if self.fillLevel > 1 then
                local baleObject = Bale.new(self.isServer, self.isClient)
                local x, y, z = getWorldTranslation(self.singleBaleNodes[i])
                local rx, ry, rz = getWorldRotation(singleBaleNode)
                if baleObject:loadFromConfigXML(self.singleBaleFilename, x, y, z, rx, ry, rz) then
                    baleObject:setFillType(self.fillType)
                    baleObject:setFillLevel((math.min(self.fillLevel, baleObject:getCapacity())))
                    baleObject:setOwnerFarmId(self.ownerFarmId, true)
                    baleObject:register()
                    self.fillLevel = self.fillLevel - baleObject:getFillLevel()
                end
            end
        end
        self:delete()
    else
        g_client:getServerConnection():sendEvent(BaleUnpackEvent.new(self))
    end
end
function PackedBale:getCanInteract()
    local x1, y1, z1 = self:getInteractionPosition()
    if x1 ~= nil then
        local x2, y2, z2 = getWorldTranslation(self.nodeId)
        if MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2) < self.maxUnpackDistance then
            return true
        end
    end
    return false
end
function PackedBale:getInteractionPosition()
    if not g_localPlayer:getIsInVehicle() then
        if g_currentMission.accessHandler:canPlayerAccess(self) then
            return g_localPlayer:getPosition()
        end
    end
end
PackedBaleActivatable = {}
local PackedBaleActivatable_mt = Class(PackedBaleActivatable)
function PackedBaleActivatable.new(packedBale)
    -- upvalues: (copy) PackedBaleActivatable_mt
    local self = setmetatable({}, PackedBaleActivatable_mt)
    self.packedBale = packedBale
    self.activateText = g_i18n:getText("action_cutBale")
    return self
end
function PackedBaleActivatable:getIsActivatable()
    return self.packedBale:getCanInteract() and true or false
end
function PackedBaleActivatable:run()
    self.packedBale:unpack()
end