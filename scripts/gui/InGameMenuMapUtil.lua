InGameMenuMapUtil = {}
InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION = {
    ["TOP_RIGHT"] = "topRight",
    ["BOTTOM_RIGHT"] = "bottomRight",
    ["BOTTOM_LEFT"] = "bottomLeft",
    ["TOP_LEFT"] = "topLeft"
}
function InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
    local posX, posY, _ = hotspot:getLastScreenPositionCenter()
    local buttonBox = contextBox:getDescendantByName("buttonBox")
    local orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
    local rotation = 0
    if posX + contextBox.size[1] > 1 then
        if posY + contextBox.size[2] + (buttonBox ~= nil and buttonBox.contentSize or 0) > 1 then
            orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
            rotation = 3.141592653589793
        else
            orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT
            rotation = 1.5707963267948966
        end
    elseif posX - contextBox.size[1] < 0 then
        if outTop then
            orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
            rotation = -1.5707963267948966
        else
            orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
        end
    elseif outTop then
        orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
        rotation = -1.5707963267948966
    end
    return posX, posY, orientation, rotation
end
function InGameMenuMapUtil.updateContextBoxPosition(contextBox, hotspot)
    if contextBox ~= nil and (contextBox:getIsVisible() and hotspot ~= nil) then
        local posX, posY, orientation, _ = InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
        local goLeft = true
        if orientation ~= InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT then
            goLeft = orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
        end
        local goDown = true
        if orientation ~= InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT then
            goDown = orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
        end
        if goLeft then
        end
        if goDown then
        end
        local buttonBox = contextBox:getDescendantByName("buttonBox")
        contextBox:setAbsolutePosition(posX, posY + (buttonBox ~= nil and (orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT or orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT) and buttonBox.contentSize or 0))
    end
end
function InGameMenuMapUtil.showContextBox(contextBox, hotspot, description, imageFilename, uvs, farmId, playerName, isPlaceable, isVehicle, isFarmland)
    if contextBox ~= nil then
        contextBox:setVisible(true)
        local x, y = InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
        local buttonBox = contextBox:getDescendantByName("buttonBox")
        contextBox:setAbsolutePosition(x, y + (buttonBox ~= nil and buttonBox.contentSize or 0))
        local hasImage = false
        if imageFilename ~= nil then
            hasImage = string.find(imageFilename, "data/store/store_empty") ~= nil
        end
        local image = contextBox:getDescendantByName("image")
        contextBox:getDescendantByName("imageVehicle"):setVisible(false)
        if isVehicle or isPlaceable then
            image:setVisible(false)
            image = contextBox:getDescendantByName("imageVehicle")
        end
        image:setVisible(hasImage)
        if hasImage then
            image:setImageFilename(imageFilename)
            image:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(uvs))
        end
        local text = contextBox:getDescendantByName("text")
        text:setText(description)
        if isFarmland then
            local farmland = hotspot:getFarmland()
            if farmland ~= nil then
                contextBox:getDescendantByName("farmlandSize"):setText(g_i18n:formatArea(farmland.areaInHa, 2))
                contextBox:getDescendantByName("farmlandValue"):setText(g_i18n:formatMoney(farmland.price, 0, true))
                text:setText(g_i18n:getText("fieldInfo_farmland") .. ": " .. farmland.name)
            end
        end
        local farmland = contextBox:getDescendantByName("farm")
        if g_currentMission.missionDynamicInfo.isMultiplayer then
            if farmId == nil then
                if playerName == nil then
                    farmland:setText("")
                else
                    farmland:setText(playerName)
                    farmland:setTextColor(unpack(Farm.COLOR_NO_FARM))
                end
            end
            local farm = g_farmManager:getFarmById(farmId)
            if farm ~= nil then
                local farmName = farm.name
                if playerName ~= nil then
                end
                farmland:setText(farmName)
                farmland:setTextColor(unpack(farm:getColor()))
                return
            end
        else
            farmland:setText("")
        end
    end
end
function InGameMenuMapUtil.showPlayerContextBox(contextBox, playerName, farmId)
    if contextBox ~= nil then
        contextBox:setVisible(true)
        local playerElem = contextBox:getDescendantByName("player")
        playerElem:setText(playerName)
        local farmElem = contextBox:getDescendantByName("farm")
        if farmId ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
            local farm = g_farmManager:getFarmById(farmId)
            if farm == nil or farm.isSpectator then
                farmElem:setText("")
                playerElem:setTextColor(0.89627, 0.92158, 0.81485, 1)
            else
                farmElem:setText(farm.name)
                farmElem:setTextColor(unpack(farm:getColor()))
                playerElem:setTextColor(unpack(farm:getColor()))
            end
        end
        farmElem:setText("")
    end
end
function InGameMenuMapUtil.hideContextBox(contextBox)
    if contextBox ~= nil then
        contextBox:setVisible(false)
    end
end
function InGameMenuMapUtil.getHotspotVehicle(hotspot)
    if hotspot == nil or hotspot.getVehicle == nil then
        return nil
    else
        return hotspot:getVehicle()
    end
end
function InGameMenuMapUtil.updateFieldInfoBoxPosition(fieldInfoBox, posX, posY)
    if fieldInfoBox ~= nil and fieldInfoBox:getIsVisible() then
        local orientation = InGameMenuMapUtil.getFieldInfoBoxOrientation(posX, posY, fieldInfoBox)
        local goLeft = true
        if orientation ~= InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT then
            goLeft = orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
        end
        local goDown = true
        if orientation ~= InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT then
            goDown = orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
        end
        if goLeft then
        end
        if goDown then
        end
        fieldInfoBox:setAbsolutePosition(posX, posY)
    end
end
function InGameMenuMapUtil.getFieldInfoBoxOrientation(posX, posY, fieldInfoBox)
    local orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
    if posX + fieldInfoBox.size[1] > 1 then
        if posY + fieldInfoBox.size[2] > 1 then
            return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
        else
            return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT
        end
    elseif posX - fieldInfoBox.size[1] < 0 then
        if outTop then
            return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
        else
            return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
        end
    else
        if outTop then
            orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
        end
        return orientation
    end
end