HandToolUtil = {}
HandToolUtil.CLICK_BOX_TARGET_MASK = CollisionFlag.INTERACTABLE_TARGET
HandToolUtil.HOLDER_DEFAULT_MINIMUM_DISTANCE = 0.25
HandToolUtil.HOLDER_DEFAULT_MAXIMUM_DISTANCE = 5
function HandToolUtil.addHandToolHolderTarget(playerTargeter, minDistance, maxDistance)
    playerTargeter:addTargetType(HandToolHolder, HandToolUtil.CLICK_BOX_TARGET_MASK, minDistance or HandToolUtil.HOLDER_DEFAULT_MINIMUM_DISTANCE, maxDistance or HandToolUtil.HOLDER_DEFAULT_MAXIMUM_DISTANCE)
    playerTargeter:addFilterToTargetType(HandToolHolder, function(hitNode, _, _, _)
        return hitNode ~= nil and hitNode ~= 0 and g_currentMission.handToolSystem:getHandToolHolderByClickBox(hitNode) ~= nil
    end)
end
function HandToolUtil.getTargetedHandToolHolder(playerTargeter)
    if not playerTargeter:getHasTargetedKey(HandToolHolder) then
        Logging.warning("HandToolUtil.getTargetedHandToolHolder was called, but HandToolUtil.CLICK_BOX_TARGET_MASK was not targeted!")
        return nil
    end
    local clickBox = playerTargeter.closestTargetsByKey[HandToolHolder]
    local handToolHolder = g_currentMission.handToolSystem
    local handToolHolder = handToolHolder:getHandToolHolderByClickBox(clickBox and clickBox.node)
    if clickBox == nil then
        return nil
    end
    if handToolHolder ~= nil then
        return handToolHolder
    end
    Logging.warning("Node with name %s is not a registered hand tool holder, yet somehow was picked up by the targeter as one!", getName(clickBox.node))
    return nil
end
function HandToolUtil.linkAndTransformRelativeToParent(rootNode, childNode, parentNode)
    link(parentNode, rootNode)
    HandToolUtil.transformRelativeToParent(rootNode, childNode, parentNode)
end
function HandToolUtil.transformRelativeToParent(rootNode, childNode, parentNode)
    local childForwardX, childForwardY, childForwardZ = localDirectionToLocal(rootNode, childNode, 0, 0, 1)
    local childUpX, childUpY, childUpZ = localDirectionToLocal(rootNode, childNode, 0, 1, 0)
    setDirection(rootNode, childForwardX, childForwardY, childForwardZ, childUpX, childUpY, childUpZ)
    setTranslation(rootNode, 0, 0, 0)
    local localChildPositionX, localChildPositionY, localChildPositionZ = localToLocal(parentNode, childNode, 0, 0, 0)
    setTranslation(rootNode, localChildPositionX, localChildPositionY, localChildPositionZ)
end