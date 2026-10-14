NetflixSigninScreen = {}
local NetflixSigninScreen_mt = Class(NetflixSigninScreen, ScreenElement)
function NetflixSigninScreen.register()
    local netflixSigninScreen = NetflixSigninScreen.new()
    g_gui:loadGui("dataS/gui/GamepadSigninScreen.xml", "NetflixSigninScreen", netflixSigninScreen)
    return netflixSigninScreen
end
function NetflixSigninScreen.new(target, custom_mt)
    -- upvalues: (copy) NetflixSigninScreen_mt
    return NetflixSigninScreen:superClass().new(target, custom_mt or NetflixSigninScreen_mt)
end
function NetflixSigninScreen.createFromExistingGui(gui, guiName)
    local newGui = NetflixSigninScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function NetflixSigninScreen:onCreate() end
function NetflixSigninScreen:onOpen()
    g_isSignedIn = false
    startMenuMusic()
    self.logo:setImageFilename("dataS/menu/main_logo_en.png")
    self.startText:setText("")
end
function NetflixSigninScreen:onClose() end
function NetflixSigninScreen:update(dt)
    NetflixSigninScreen:superClass().update(self, dt)
    if getIsUserSignedIn() then
        g_isSignedIn = true
        loadUserSettings(g_gameSettings)
        self:changeScreen(MainScreen)
    end
end