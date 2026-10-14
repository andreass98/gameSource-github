DebugPhysicsCollisionGroupDialog = {}
local DebugPhysicsCollisionGroupDialog_mt = Class(DebugPhysicsCollisionGroupDialog, InfoDialog)
function DebugPhysicsCollisionGroupDialog.register()
    local debugPhysicsCollisionGroupDialog = DebugPhysicsCollisionGroupDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/debug/DebugPhysicsCollisionGroupDialog.xml", "DebugPhysicsCollisionGroupDialog", debugPhysicsCollisionGroupDialog)
    DebugPhysicsCollisionGroupDialog.INSTANCE = debugPhysicsCollisionGroupDialog
    if g_isDevelopmentVersion then
        g_messageCenter:subscribe(MessageType.DEBUG_MODE_CHANGED, DebugPhysicsCollisionGroupDialog.onDebugModeChanged, DebugPhysicsCollisionGroupDialog)
    end
end
function DebugPhysicsCollisionGroupDialog.show()
    if DebugPhysicsCollisionGroupDialog.INSTANCE ~= nil then
        g_gui:showDialog("DebugPhysicsCollisionGroupDialog")
    end
end
function DebugPhysicsCollisionGroupDialog.onDebugModeChanged(_, debugMode)
    if debugMode == DebugMode.PHYSICS and Input.isKeyPressed(Input.KEY_lalt) then
        DebugPhysicsCollisionGroupDialog.show()
    else
        g_gui:closeDialogByName("DebugPhysicsCollisionGroupDialog")
    end
end
function DebugPhysicsCollisionGroupDialog.new(target, custom_mt)
    -- upvalues: (copy) DebugPhysicsCollisionGroupDialog_mt
    local self = TextInputDialog.new(target, custom_mt or DebugPhysicsCollisionGroupDialog_mt)
    addConsoleCommand("gsDebugPhysicsCollisionsGroup", "Opens a dialog to modify collision group debug options", "openDialog", self)
    return self
end
function DebugPhysicsCollisionGroupDialog.createFromExistingGui(gui, guiName)
    DebugPhysicsCollisionGroupDialog.register()
    DebugPhysicsCollisionGroupDialog.show()
end
function DebugPhysicsCollisionGroupDialog:onGuiSetupFinished()
    DebugPhysicsCollisionGroupDialog:superClass().onGuiSetupFinished(self)
    self.binaryTemplate:unlinkElement()
    FocusManager:removeElement(self.binaryTemplate)
    self.sliderTemplate:unlinkElement()
    FocusManager:removeElement(self.sliderTemplate)
    self.binaryTemplate:getDescendantByName("option"):setTexts({ "Hide", "Show" })
    self.sliderTemplate:getDescendantByName("option"):setTexts({ "Hide", "Show", "No Depth" })
    self.elementsBox:addElement(self.titlePhysics)
    self.elementsBox:addElement(self.subtitlePhysics)
    for flagName, flag in pairs(PhysicsDebugDrawMode) do
        local option = self.sliderTemplate:clone(self.elementsBox)
        option:getDescendantByName("title"):setText(string.gsub(flagName, "COLLISION_GEOMETRIES_", ""))
        local option = option:getDescendantByName("option")
        option.bit = math.log(flag, 2)
        option.flag = flag
    end
    self.elementsBox:addElement(self.titleCollisions)
    for flagName, flag, option in CollisionFlag.iteratorFlags() do
        local option = self.binaryTemplate:clone(self.elementsBox)
        option:getDescendantByName("title"):setText(flagName)
        option.isCollisionOption = true
        local option = option:getDescendantByName("option")
        option.bit = flag
        option.flag = option
    end
    self.elementsBox:invalidateLayout()
end
function DebugPhysicsCollisionGroupDialog:delete()
    self.binaryTemplate:delete()
    self.sliderTemplate:delete()
    if g_isDevelopmentVersion then
        g_messageCenter:unsubscribeAll(DebugPhysicsCollisionGroupDialog)
    end
    DebugPhysicsCollisionGroupDialog:superClass().delete(self)
end
function DebugPhysicsCollisionGroupDialog:openDialog()
    if g_currentMission == nil then
        Logging.warning("Can only open this dialog while a savegame is loaded")
    else
        DebugPhysicsCollisionGroupDialog.show()
    end
end
function DebugPhysicsCollisionGroupDialog:onOpen()
    DebugPhysicsCollisionGroupDialog:superClass().onOpen(self)
    local bitmaskCollision = getPhysicsDebugDrawCollisionFilterGroup()
    local bitmaskNoDepth = getPhysicsDebugDrawNoDepthMode()
    local bitmaskPhysicsDrawMode = getPhysicsDebugDrawMode()
    for _, element in pairs(self.elementsBox.elements) do
        local option = element:getDescendantByName("option")
        if option ~= nil then
            if element.isCollisionOption then
                option:setState(Utils.isBitSet(bitmaskCollision, option.bit) and 2 or 1)
            else
                local state = 1
                if Utils.isBitSet(bitmaskPhysicsDrawMode, option.bit) then
                    state = Utils.isBitSet(bitmaskNoDepth, option.bit) and 3 or 2
                end
                option:setState(state)
            end
        end
    end
    setPhysicsDebugDrawEnabled(true)
end
function DebugPhysicsCollisionGroupDialog:selectAll()
    for _, element in pairs(self.elementsBox.elements) do
        local option = element:getDescendantByName("option")
        if option ~= nil and element.isCollisionOption then
            option:setState(2)
        end
    end
    self:applyChanges()
end
function DebugPhysicsCollisionGroupDialog:unselectAll()
    for _, element in pairs(self.elementsBox.elements) do
        local option = element:getDescendantByName("option")
        if option ~= nil and element.isCollisionOption then
            option:setState(1)
        end
    end
    self:applyChanges()
end
function DebugPhysicsCollisionGroupDialog:onClickApply()
    self:applyChanges()
end
function DebugPhysicsCollisionGroupDialog:onClickOk()
    self:applyChanges()
    self:close()
end
function DebugPhysicsCollisionGroupDialog:applyChanges()
    local flagSumCollision = 0
    local flagSumPhysicsDrawMode = 0
    local flagSumNoDepth = 0
    for _, element in pairs(self.elementsBox.elements) do
        local option = element:getDescendantByName("option")
        if option ~= nil then
            local state = option.state
            if state >= 2 then
                if element.isCollisionOption then
                elseif state == 3 then
                end
            end
        end
    end
    if getPhysicsDebugDrawCollisionFilterGroup() ~= flagSumCollision then
        setPhysicsDebugDrawCollisionFilterGroup(flagSumCollision)
    end
    if getPhysicsDebugDrawNoDepthMode() ~= flagSumNoDepth then
        setPhysicsDebugDrawNoDepthMode(flagSumNoDepth)
    end
    if getPhysicsDebugDrawMode() ~= flagSumPhysicsDrawMode then
        setPhysicsDebugDrawMode(flagSumPhysicsDrawMode)
    end
end