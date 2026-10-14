WardrobeCharactersFrame = {}
local WardrobeCharactersFrame_mt = Class(WardrobeCharactersFrame, TabbedMenuFrameElement)
function WardrobeCharactersFrame.register()
    local wardrobeCharactersFrame = WardrobeCharactersFrame.new()
    g_gui:loadGui("dataS/gui/WardrobeCharactersFrame.xml", "WardrobeCharactersFrame", wardrobeCharactersFrame, true)
end
function WardrobeCharactersFrame.new(target, custom_mt)
    -- upvalues: (copy) WardrobeCharactersFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or WardrobeCharactersFrame_mt)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK,
        ["text"] = g_i18n:getText("button_confirm")
    }
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ["callback"] = self.onPageNext
    }
    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ["callback"] = self.onPagePrevious
    }
    self.selectButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText("button_select"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickSelect()
        end
    }
    self.nicknameButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_changeName"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickChangeName()
        end
    }
    self.hasCustomMenuButtons = true
    self.menuButtonInfo = {
        self.backButtonInfo,
        self.nextPageButtonInfo,
        self.prevPageButtonInfo,
        self.selectButtonInfo
    }
    if Platform.canChangeGamerTag then
        table.insert(self.menuButtonInfo, self.nicknameButtonInfo)
    end
    self.mapping = {}
    return self
end
function WardrobeCharactersFrame.createFromExistingGui(gui, guiName)
    local newGui = WardrobeCharactersFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function WardrobeCharactersFrame:initialize(configName, delegate, titleKey, sliceId)
    self.configName = configName
    self.delegate = delegate
    self.title:setLocaKey(titleKey)
    self.headerIcon:setImageSlice(nil, sliceId)
    self:loadPlayers()
end
function WardrobeCharactersFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
    self.playerStyle = playerStyle
    self.savedPlayerStyle = savedPlayerStyle
    self:resetList()
end
function WardrobeCharactersFrame:onFrameOpen()
    WardrobeCharactersFrame:superClass().onFrameOpen(self)
    self.delegate:onItemSelectionStart()
    self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
    g_messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onNicknameChanged, self)
    self:resetList()
end
function WardrobeCharactersFrame:resetList()
    self.mapping = {}
    if self.playerStyle ~= nil then
        local selectedIndex = 1
        for playerIndex, player in ipairs(self.players) do
            for i, item in ipairs(player.style.configs.face.items) do
                if item.isSelectable then
                    table.insert(self.mapping, {
                        ["xmlFilename"] = player.xmlFilename,
                        ["iconFilename"] = item.iconFilename,
                        ["index"] = i,
                        ["style"] = player.style
                    })
                    if self.playerStyle.configs.face.selectedItemIndex == i and self.playerStyle.xmlFilename == player.xmlFilename then
                        selectedIndex = #self.mapping
                    end
                end
            end
        end
        self.itemList:reloadData()
        self.itemList:setSelectedItem(1, selectedIndex)
    end
    FocusManager:setFocus(self.itemList)
end
function WardrobeCharactersFrame:onFrameClose()
    for _, cell in ipairs(self.itemList.elements) do
        if cell:getAttribute("icon") ~= nil then
            cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
        end
    end
    g_messageCenter:unsubscribe(MessageType.PLAYER_NICKNAME_CHANGED, self)
    WardrobeCharactersFrame:superClass().onFrameClose(self)
end
function WardrobeCharactersFrame:loadPlayers()
    self.players = {}
    for _, playerStyleConfig in pairs(PlayerSystem.PLAYER_STYLES_BY_FILENAME) do
        local playerStyle = PlayerStyle.new()
        playerStyle:copyFrom(playerStyleConfig.style)
        table.insert(self.players, {
            ["xmlFilename"] = playerStyleConfig.filename,
            ["style"] = playerStyle
        })
    end
end
function WardrobeCharactersFrame:getNumberOfItemsInSection(_, _)
    return #self.mapping
end
function WardrobeCharactersFrame:populateCellForItemInSection(_, _, index, cell)
    local item = self.mapping[index]
    local function getIsSelectedFunc()
        -- upvalues: (copy) self, (copy) item
        return self.savedPlayerStyle.configs.face.selectedItemIndex == item.index and self.savedPlayerStyle.xmlFilename == item.xmlFilename
    end
    cell:getAttribute("icon"):setImageFilename(item.iconFilename)
    cell:getAttribute("icon"):setVisible(item.iconFilename ~= nil)
    cell:getAttribute("icon").getIsSelected = getIsSelectedFunc
    cell:getAttribute("background").getIsSelected = getIsSelectedFunc
    cell:getAttribute("background").getIsFocused = function()
        -- upvalues: (copy) cell
        return cell.selected
    end
end
function WardrobeCharactersFrame:onListSelectionChanged(_, _, index)
    local item = self.mapping[index]
    if self.playerStyle.xmlFilename ~= item.xmlFilename then
        self.playerStyle:loadConfigurationXML(item.xmlFilename)
    end
    local beardConfig = self.playerStyle.configs.beard
    local possibleItemIndices = beardConfig:getPossibleItemIndices()
    local oldSelectedBeardIndex = -1
    for k, index in ipairs(possibleItemIndices) do
        if index == beardConfig.selectedItemIndex then
            oldSelectedBeardIndex = k
            break
        end
    end
    self.playerStyle.configs.face:setSelectedItemIndex(item.index)
    local beardConfigIndex = beardConfig:getPossibleItemIndices()[oldSelectedBeardIndex]
    if beardConfigIndex ~= nil then
        beardConfig:setSelectedItemIndex(beardConfigIndex)
    end
    self.delegate:onItemSelectionChanged()
end
function WardrobeCharactersFrame:onClickSelect(_)
    self.delegate:onItemSelectionConfirmed()
    self.itemList:reloadData()
end
function WardrobeCharactersFrame:onClickChangeName()
    local text = g_i18n:getText("ui_enterName")
    local imePrompt = g_i18n:getText("ui_enterName")
    local confirmText = g_i18n:getText("button_change")
    TextInputDialog.show(function(newName, ok)
        -- upvalues: (copy) self
        if ok and newName ~= g_currentMission.playerNickname then
            g_currentMission:setPlayerNickname(g_localPlayer, newName)
            self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
        end
    end, nil, g_currentMission.playerNickname, nil, imePrompt, nil, confirmText, nil, text)
end
function WardrobeCharactersFrame:onNicknameChanged()
    self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
end