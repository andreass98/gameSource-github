ShipStatic = {}
local ShipStatic_mt = Class(ShipStatic, Object)
InitStaticObjectClass(ShipStatic, "ShipStatic")
g_xmlManager:addInitSchemaFunction(function()
    local savegameSchema = OnCreateObjectSystem.xmlSchemaSavegame
    savegameSchema:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?)#isVisible", "If ship is visible")
    savegameSchema:register(XMLValueType.BOOL, "onCreateLoadedObjects.object(?)#isSwitchPending", "If ship visibilit switch is pending")
    savegameSchema:register(XMLValueType.INT, "onCreateLoadedObjects.object(?)#nextChangeHour", "Next switching hour")
end)
function ShipStatic.onCreate(_, node)
    local ship = ShipStatic.new
    local ship = ship(g_server ~= nil, g_client ~= nil)
    if ship:load(node) then
        ship:register(true)
    else
        ship:delete()
    end
end
function ShipStatic.new(isServer, isClient, customMt)
    -- upvalues: (copy) ShipStatic_mt
    return Object.new(isServer, isClient, customMt or ShipStatic_mt)
end
function ShipStatic:load(node)
    self.rootNode = node
    self.isVisible = true
    self.nextChangeHour = math.random(0, 23)
    self.isSwitchPending = false
    self.saveId = getName(node)
    if self.isServer then
        self.dirtyFlag = self:getNextDirtyFlag()
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    end
    g_currentMission.onCreateObjectSystem:add(self, true)
    return true
end
function ShipStatic:delete()
    g_messageCenter:unsubscribeAll(self)
    ShipStatic:superClass().delete(self)
end
function ShipStatic:loadFromXMLFile(xmlFile, key)
    self.isVisible = xmlFile:getValue(key .. "#isVisible", self.isVisible)
    self.isSwitchPending = xmlFile:getValue(key .. "#isSwitchPending", self.isSwitchPending)
    self.nextChangeHour = xmlFile:getValue(key .. "#nextChangeHour", self.nextChangeHour)
    self:setVisibility(self.isVisible)
    if self.isSwitchPending then
        self:raiseActive()
    end
    return true
end
function ShipStatic:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#isVisible", self.isVisible)
    xmlFile:setValue(key .. "#isSwitchPending", self.isSwitchPending)
    xmlFile:setValue(key .. "#nextChangeHour", self.nextChangeHour)
end
function ShipStatic:setVisibility(isVisible)
    self.isVisible = isVisible
    setVisibility(self.rootNode, isVisible)
    if isVisible then
        addToPhysics(self.rootNode)
    else
        removeFromPhysics(self.rootNode)
    end
end
function ShipStatic:readStream(streamId, connection, _)
    if connection:getIsServer() then
        self:setVisibility(streamReadBool(streamId))
    end
end
function ShipStatic:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.isVisible)
    end
end
function ShipStatic:readUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        self:setVisibility(streamReadBool(streamId))
    end
end
function ShipStatic:writeUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.isVisible)
    end
end
function ShipStatic:updateTick(_)
    if self.isServer and self.isSwitchPending then
        local x, y, z = getWorldTranslation(self.rootNode)
        local clipDistance = getEffectiveClipDistancesWithLOD(self.rootNode)
        local isInRange = false
        for _, streamId in ipairs(g_server.clients) do
            local cx, cy, cz = g_server:getClientPosition(streamId)
            if MathUtil.vector3Length(x - cx, y - cy, z - cz) < clipDistance then
                isInRange = true
                break
            end
        end
        if not isInRange then
            self:setVisibility(not self.isVisible)
            self:raiseDirtyFlags(self.dirtyFlag)
            self.isSwitchPending = false
            return
        end
        self:raiseActive()
    end
end
function ShipStatic:onHourChanged(currentHour)
    if self.isServer and self.nextChangeHour == currentHour then
        self.isSwitchPending = true
        self.nextChangeHour = (self.nextChangeHour + math.random(5, 23)) % 23
        self:raiseActive()
    end
end