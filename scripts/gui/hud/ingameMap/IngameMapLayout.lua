IngameMapLayout = {}
local IngameMapLayout_mt = Class(IngameMapLayout)
function IngameMapLayout.new(customMt)
    -- upvalues: (copy) IngameMapLayout_mt
    return setmetatable({}, customMt or IngameMapLayout_mt)
end
function IngameMapLayout:delete() end
function IngameMapLayout:activate() end
function IngameMapLayout:deactivate() end
function IngameMapLayout:createComponents(element) end
function IngameMapLayout:storeScaledValues(element, uiScale) end
function IngameMapLayout:drawBefore() end
function IngameMapLayout:drawAfter() end
function IngameMapLayout:drawCoordinates(text) end
function IngameMapLayout:drawLatency(text, color) end
function IngameMapLayout:setPlayerPosition(x, z, yRot) end
function IngameMapLayout:setPlayerVelocity(speed) end
function IngameMapLayout:setWorldSize(worldSizeX, worldSizeZ) end
function IngameMapLayout:setMapExtensionSettings(extensionScale, extensionOffsetX, extensionOffsetZ) end
function IngameMapLayout:setHasUnreadMessages(hasMessages) end
function IngameMapLayout:getMapPivot()
    return 0, 0
end
function IngameMapLayout:getMapRotation()
    return 0
end
function IngameMapLayout:getMapSize()
    return 1, 1
end
function IngameMapLayout:getMapPosition()
    return 0, 0
end
function IngameMapLayout:getMapAlpha()
    return 1
end
function IngameMapLayout:getShowsToggleAction()
    return true
end
function IngameMapLayout:getShowsToggleActionText()
    return false
end
function IngameMapLayout:getIconZoom()
    return 1
end
function IngameMapLayout:getShowSmallIconVariation()
    return false
end
function IngameMapLayout:getBlinkPlayerArrow()
    return false
end
function IngameMapLayout:postUpdate(dt) end
function IngameMapLayout:getHeight()
    return 0
end
function IngameMapLayout:getWidth()
    return 0
end
function IngameMapLayout:getPosition()
    return 0, 0
end
function IngameMapLayout:getMapObjectPosition(objectX, objectZ, width, height, rot, persistent)
    return 0, 0, 0, false
end