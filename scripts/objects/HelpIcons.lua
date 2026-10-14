HelpIcons = {}
local HelpIcons_mt = Class(HelpIcons)
function HelpIcons.onCreate(_, id)
    local helpIcons = HelpIcons.new(id)
    g_currentMission:addNonUpdateable(helpIcons)
    g_currentMission.helpIconsBase = helpIcons
end
function HelpIcons.new(name)
    -- upvalues: (copy) HelpIcons_mt
    local self = setmetatable({}, HelpIcons_mt)
    self.me = name
    local num = getNumOfChildren(self.me)
    self.helpIcons = {}
    local i = 0
    for i = i, num - 1 do
        local helpIconTriggerId = getChildAt(self.me, i)
        local helpIconId = getChildAt(helpIconTriggerId, 0)
        local helpIconCustomNumber = Utils.getNoNil(getUserAttribute(helpIconTriggerId, "customNumber"), 0)
        addTrigger(helpIconTriggerId, "triggerCallback", self)
        table.insert(self.helpIcons, {
            ["helpIconTriggerId"] = helpIconTriggerId,
            ["helpIconId"] = helpIconId,
            ["helpIconCustomNumber"] = helpIconCustomNumber
        })
    end
    self.visible = true
    return self
end
function HelpIcons:delete()
    for _, helpIcon in pairs(self.helpIcons) do
        removeTrigger(helpIcon.helpIconTriggerId)
    end
end
function HelpIcons:update(dt) end
function HelpIcons:triggerCallback(triggerId, otherId, onEnter, _, _)
    if onEnter then
        local localPlayer = g_localPlayer
        if localPlayer == nil then
            return
        elseif localPlayer:getIsInVehicle() or otherId == localPlayer.rootNode then
            local playerVehicle = localPlayer:getCurrentVehicle()
            if playerVehicle ~= nil and playerVehicle == g_currentMission.nodeToObject[otherId] then
                for i, helpIcon in ipairs(self.helpIcons) do
                    if helpIcon.helpIconTriggerId == triggerId and getVisibility(helpIcon.helpIconId) then
                        setVisibility(helpIcon.helpIconId, false)
                        setCollisionFilterMask(helpIcon.helpIconTriggerId, 0)
                        g_currentMission.missionInfo.foundHelpIcons = ""
                        for _, helpIcon in ipairs(self.helpIcons) do
                            if getVisibility(helpIcon.helpIconId) then
                                missionInfo.foundHelpIcons = missionInfo.foundHelpIcons .. "0"
                            else
                                missionInfo.foundHelpIcons = missionInfo.foundHelpIcons .. "1"
                            end
                        end
                        local messageNumber = helpIcon.helpIconCustomNumber
                        if messageNumber ~= 0 then
                            local i = messageNumber
                        end
                        g_currentMission.inGameMessage:showMessage(g_i18n:getText("helpIcon_title" .. i), g_i18n:getText("helpIcon_text" .. i), 0)
                    end
                end
            end
        else
            return
        end
    else
        return
    end
end
function HelpIcons:showHelpIcons(visible, clearIconStates)
    self.visible = visible
    for i, helpIcon in ipairs(self.helpIcons) do
        local isVisible
        if clearIconStates == nil or not clearIconStates then
            isVisible = visible and string.sub(g_currentMission.missionInfo.foundHelpIcons, i, i) == "0"
        else
            isVisible = visible
        end
        setVisibility(helpIcon.helpIconId, isVisible)
        if isVisible then
            setCollisionFilterMask(helpIcon.helpIconTriggerId, 3145728)
        else
            setCollisionFilterMask(helpIcon.helpIconTriggerId, 0)
        end
    end
end
function HelpIcons:deleteHelpIcon(i)
    if self.helpIcons[i] ~= nil then
        setVisibility(self.helpIcons[i].helpIconId, false)
        setCollisionFilterMask(self.helpIcons[i].helpIconTriggerId, 0)
    end
end