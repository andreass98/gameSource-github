DialogElement = {}
DialogElement.TYPE_LOADING = 0
DialogElement.TYPE_QUESTION = 1
DialogElement.TYPE_WARNING = 2
DialogElement.TYPE_KEY = 3
DialogElement.TYPE_INFO = 4
DialogElement.DIALOG_CIRCLE_PROFILE = "fs25_dialogCircle"
DialogElement.DIALOG_CIRCLE_PROFILE_WARNING = "fs25_dialogCircleWarning"
DialogElement.CONTROLS = {
    ["ICON_LOADING_ELEMENT"] = "iconLoadingElement",
    ["ICON_QUESTION_ELEMENT"] = "iconQuestionElement",
    ["ICON_WARNING_ELEMENT"] = "iconWarningElement",
    ["ICON_KEY_ELEMENT"] = "iconKeyElement",
    ["ICON_INFO_ELEMENT"] = "iconInfoElement"
}
local TYPE_ICON_ID_MAPPING = {
    [DialogElement.TYPE_LOADING] = DialogElement.CONTROLS.ICON_LOADING_ELEMENT,
    [DialogElement.TYPE_QUESTION] = DialogElement.CONTROLS.ICON_QUESTION_ELEMENT,
    [DialogElement.TYPE_WARNING] = DialogElement.CONTROLS.ICON_WARNING_ELEMENT,
    [DialogElement.TYPE_KEY] = DialogElement.CONTROLS.ICON_KEY_ELEMENT,
    [DialogElement.TYPE_INFO] = DialogElement.CONTROLS.ICON_INFO_ELEMENT
}
local DialogElement_mt = Class(DialogElement, ScreenElement)
function DialogElement.new(target, custom_mt)
    -- upvalues: (copy) DialogElement_mt
    local self = ScreenElement.new(target, custom_mt or DialogElement_mt)
    self.isCloseAllowed = true
    return self
end
function DialogElement:close()
    g_gui:closeDialogByName(self.name)
end
function DialogElement:onClickBack(forceBack, usedMenuButton)
    if not (self.isCloseAllowed or forceBack) or usedMenuButton then
        return true
    end
    self:close()
    return false
end
function DialogElement:setDialogType(dialogType)
    -- upvalues: (copy) TYPE_ICON_ID_MAPPING
    dialogType = dialogType or DialogElement.TYPE_WARNING
    self.dialogType = dialogType
    for dt, id in pairs(TYPE_ICON_ID_MAPPING) do
        local typeElement = self[id]
        if typeElement then
            typeElement:setVisible(dt == dialogType)
        end
    end
    if self.dialogCircle ~= nil then
        self.dialogCircle:setVisible(dialogType ~= DialogElement.TYPE_LOADING)
        if dialogType == DialogElement.TYPE_WARNING then
            self.dialogCircle:applyProfile(DialogElement.DIALOG_CIRCLE_PROFILE_WARNING)
            return
        end
        self.dialogCircle:applyProfile(DialogElement.DIALOG_CIRCLE_PROFILE)
    end
end
function DialogElement:setIsCloseAllowed(isAllowed)
    self.isCloseAllowed = isAllowed
end
function DialogElement:getBlurArea()
    return nil
end