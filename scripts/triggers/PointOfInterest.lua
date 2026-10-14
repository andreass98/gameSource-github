PointOfInterest = {}
local PointOfInterest_mt = Class(PointOfInterest)
function PointOfInterest.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.STRING, basePath .. "#text", "POI text")
    schema:register(XMLValueType.STRING, basePath .. "#textFormat", "POI text additional format string")
    schema:register(XMLValueType.STRING, basePath .. "#textParams", "POI text format parameters")
    schema:register(XMLValueType.BOOL, basePath .. "#showOwner", "Show only for owners")
    schema:register(XMLValueType.BOOL, basePath .. "#showEveryone", "Show everyone")
end
function PointOfInterest.onCreate(_, id)
    local poi = PointOfInterest:new()
    if poi:loadFromNode(id) then
        g_currentMission:addNonUpdateable(poi)
    else
        poi:delete()
    end
end
function PointOfInterest.new(placeable, customEnv, customMt)
    -- upvalues: (copy) PointOfInterest_mt
    local self = setmetatable({}, customMt or PointOfInterest_mt)
    self.placeable = placeable
    self.infoText = nil
    self.isEnabled = true
    self.customEnv = customEnv
    self.isPlayerInRange = false
    self.showOwner = true
    self.showEveryone = true
    self.vehicleNodesInRange = {}
    self.ownerFarmId = nil
    return self
end
function PointOfInterest:load(components, xmlFile, key, _, i3dMappings, _)
    self.node = xmlFile:getValue(key .. "#triggerNode", nil, components, i3dMappings)
    CollisionFlag.setMaskFlag(self.node, CollisionFlag.PLAYER)
    CollisionFlag.setMaskFlag(self.node, CollisionFlag.VEHICLE)
    if self.node == nil then
        Logging.devWarning("Missing node for PointOfInterest \'%s\'", key)
        return false
    end
    local text = xmlFile:getValue(key .. "#text")
    if text == nil then
        Logging.xmlWarning(xmlFile, "Missing text for PointOfInterest \'%s\' (node \'%s\')", key, getName(self.node))
        return false
    end
    self.infoText = g_i18n:convertText(text, self.customEnv)
    local formatStr = xmlFile:getValue(key .. "#textFormat")
    local params = xmlFile:getValue(key .. "#textParams")
    if params ~= nil then
        if formatStr == nil then
            self.infoText = g_i18n:insertTextParams(self.infoText, params, self.customEnv, xmlFile)
        else
            local formatStr = g_i18n:insertTextParams(formatStr, params, self.customEnv, xmlFile)
            self.infoText = string.format(self.infoText, formatStr)
        end
    end
    self.showOwner = xmlFile:getValue(key .. "#showOwner", self.showOwner)
    self.showEveryone = xmlFile:getValue(key .. "#showEveryone", self.showEveryone)
    self:finalize()
    return true
end
function PointOfInterest:loadFromNode(node)
    self.node = node
    PointOfInterest.checkCollisionMask(node, nil)
    local text = getUserAttribute(node, "text")
    self.showOwner = getUserAttribute(node, "showOwner") == "true"
    self.showEveryone = getUserAttribute(node, "showEveryone") == "true"
    if text == nil then
        Logging.devWarning("Missing text for PointOfInterest \'%s\'", getName(self.node))
        return false
    end
    self.infoText = g_i18n:convertText(text, self.customEnv)
    self:finalize()
    return true
end
function PointOfInterest:finalize()
    if g_currentMission:getIsClient() then
        self.callbackId = addTrigger(self.node, "PointOfInterest:triggerCallback", self, false, self.triggerCallback)
    end
end
function PointOfInterest:delete()
    if self.callbackId ~= nil then
        removeTrigger(self.node, self.callbackId)
        self.callbackId = nil
    end
    g_currentMission:removeDrawable(self)
end
function PointOfInterest:getNeedsDrawing()
    if not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_TRIGGER) or (not self.isEnabled or self.infoText == nil) then
        return false
    end
    local needsDrawing = self.isPlayerInRange
    local farmId = g_currentMission:getFarmId()
    if not needsDrawing then
        for node, _ in pairs(self.vehicleNodesInRange) do
            if entityExists(node) then
                local vehicle = g_currentMission:getNodeObject(node)
                if vehicle ~= nil and vehicle == g_localPlayer:getCurrentVehicle() then
                    farmId = vehicle:getOwnerFarmId()
                    needsDrawing = true
                end
            else
                self.vehicleNodesInRange[node] = nil
            end
        end
    end
    if needsDrawing then
        if self.ownerFarmId == AccessHandler.EVERYONE then
            if not self.showEveryone then
                return false
            end
        elseif self.ownerFarmId == farmId then
            if not self.showOwner then
                return false
            end
        else
            needsDrawing = false
        end
    end
    return needsDrawing
end
function PointOfInterest:draw()
    if self:getNeedsDrawing() then
        g_currentMission.hud:setPOIInfoText(self.infoText)
    end
end
function PointOfInterest:triggerCallback(_, otherId, onEnter, onLeave, _, _)
    if onEnter or onLeave then
        local changed
        if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
            if onEnter then
                self.vehicleNodesInRange[otherId] = true
                changed = true
            else
                self.vehicleNodesInRange[otherId] = nil
                changed = true
            end
        elseif onEnter then
            self.isPlayerInRange = true
            changed = true
        else
            self.isPlayerInRange = false
            changed = true
        end
        if changed then
            if self.isPlayerInRange or next(self.vehicleNodesInRange) ~= nil then
                g_currentMission:addDrawable(self)
                return
            end
            g_currentMission:removeDrawable(self)
        end
    end
end
function PointOfInterest:setOwnerFarmId(farmId)
    self.ownerFarmId = farmId
end