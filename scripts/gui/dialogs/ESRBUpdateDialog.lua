ESRBUpdateDialog = {}
local ESRBUpdateDialog_mt = Class(ESRBUpdateDialog, InfoDialog)
function ESRBUpdateDialog.register()
    local esrbUpdateDialog = ESRBUpdateDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "ESRBUpdateDialog", esrbUpdateDialog)
    ESRBUpdateDialog.INSTANCE = esrbUpdateDialog
end
function ESRBUpdateDialog.show(text, callback, target)
    if ESRBUpdateDialog.INSTANCE ~= nil then
        local dialog = ESRBUpdateDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog:setText(text)
        g_gui:showDialog("ESRBUpdateDialog")
    end
end
function ESRBUpdateDialog.new(target, custom_mt)
    -- upvalues: (copy) ESRBUpdateDialog_mt
    return InfoDialog.new(target, custom_mt or ESRBUpdateDialog_mt)
end
function ESRBUpdateDialog:update(dt)
    ESRBUpdateDialog:superClass().update(self, dt)
    local d = 1
    for d = d, getNumOfGamepads() do
        local i = 1
        for i = i, Input.MAX_NUM_BUTTONS do
            local isDown = getInputButton(i - 1, d - 1) > 0
            if isDown then
                self:onClickOk()
                break
            end
        end
    end
end
function ESRBUpdateDialog:keyEvent(_, _, _, isDown)
    if isDown then
        self:onClickOk()
    end
end
function ESRBUpdateDialog:mouseEvent(_, _, isDown, _, _)
    if isDown then
        self:onClickOk()
    end
end