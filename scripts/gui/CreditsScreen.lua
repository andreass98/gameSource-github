CreditsScreen = {}
CreditsScreen.TITLE = 0
CreditsScreen.TEXT = 1
CreditsScreen.SEPARATOR = 2
CreditsScreen.DISCLAIMER = 3
CreditsScreen.LIST_TEMPLATE_ELEMENT_NAME = {}
local CreditsScreen_mt = Class(CreditsScreen, ScreenElement)
function CreditsScreen.register()
    local creditsScreen = CreditsScreen.new()
    g_gui:loadGui("dataS/gui/CreditsScreen.xml", "CreditsScreen", creditsScreen)
end
function CreditsScreen.new(target, custom_mt)
    -- upvalues: (copy) CreditsScreen_mt
    local self = ScreenElement.new(target, custom_mt or CreditsScreen_mt)
    self:setReturnScreenClass(MainScreen)
    return self
end
function CreditsScreen.createFromExistingGui(gui, guiName)
    local newGui = CreditsScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function CreditsScreen:onCreate(_)
    self.creditsTitleElement:unlinkElement()
    self.creditsTextElement:unlinkElement()
    self.creditsDisclaimerElement:unlinkElement()
    self:loadCredits()
    self.creditsStartY = self.creditsPlaceholder.absPosition[2]
end
function CreditsScreen:onOpen()
    CreditsScreen:superClass().onOpen(self)
    self.creditsPlaceholder:invalidateLayout(true)
    if Platform.isMobile then
        local mainContainerSize = (g_screenWidth - self.sidebar.absSize[1] * g_screenWidth - 50) * g_pixelSizeX
        self.mainContainer.absSize[1] = mainContainerSize
        self.creditsVisibilityBox:setAnchors(0, 1 - (mainContainerSize - self.creditsVisibilityBox.size[1]), 0.1, 0.9)
        self.mainContainer.absPosition[1] = 1 - mainContainerSize
        self.mainContainer:setAnchors(self.mainContainer.absPosition[1], 1, 0, 1)
        self.mainContainer:updateAbsolutePosition()
        if getPlatformId() == PlatformId.ANDROID then
            self.achievementsButton:setDisabled(not getIsUserSignedIn())
        end
    end
    if Platform.hasMainScreenLanguageSelection then
        self.changeLanguageButton:setVisible(true)
        self.buttonBox:invalidateLayout()
    end
    for _, item in pairs(self.creditsElements) do
        item:setAlpha(0)
    end
    self.nextFadeInCreditsItemId = 1
    self.nextFadeOutCreditsItemId = 1
    self.creditsPlaceholder:setAbsolutePosition(self.creditsPlaceholder.absPosition[1], self.creditsStartY)
    if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "highlandsFishingPack"] == nil then
        self.backgroundImage:setImageFilename("shared/splash.png")
    else
        self.backgroundImage:setImageFilename("shared/splash_highlandsFishing.png")
    end
    self:updateTheme()
end
function CreditsScreen:delete()
    self.creditsTitleElement:delete()
    self.creditsTextElement:delete()
    self.creditsDisclaimerElement:delete()
    CreditsScreen:superClass().delete(self)
end
function CreditsScreen:update(dt)
    CreditsScreen:superClass().update(self, dt)
    self.creditsPlaceholder:setAbsolutePosition(self.creditsPlaceholder.absPosition[1], self.creditsPlaceholder.absPosition[2] + 0.00007 * dt)
    if self.nextFadeInCreditsItemId <= #self.creditsElements and self.creditsElements[self.nextFadeInCreditsItemId].absPosition[2] > self.creditsVisibilityBox.absPosition[2] then
        self.creditsElements[self.nextFadeInCreditsItemId]:fadeIn(1.2)
        self.nextFadeInCreditsItemId = self.nextFadeInCreditsItemId + 1
    end
    if self.nextFadeOutCreditsItemId <= #self.creditsElements then
        if self.creditsElements[self.nextFadeOutCreditsItemId].absPosition[2] > self.creditsVisibilityBox.absPosition[2] + self.creditsVisibilityBox.absSize[2] * 0.8 then
            self.creditsElements[self.nextFadeOutCreditsItemId]:fadeOut(4)
            self.nextFadeOutCreditsItemId = self.nextFadeOutCreditsItemId + 1
            return
        end
    else
        self:onClickBack()
    end
end
function CreditsScreen:loadCredits()
    local creditsTexts = {}
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Developed by"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "GIANTS Software GmbH"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Executive Producer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Christian Ammann"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Chief Technical Officer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Stefan Geiger"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Creative Director"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Thomas Frey"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Level Designer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Renzo Th\195\182nen"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Programmer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Thomas Brunner"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Gameplay Programmer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Manuel Leithner"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Tools Programmer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Rudolf-Walter Kiss-Szak\195\161cs"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Artist"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marc Schwegler"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Studio Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Luk\195\161\197\161 Ku\197\153e"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    if Platform.isPlaystation then
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TITLE,
            ["c"] = "Senior PlayStation\194\1745 Programmer"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TEXT,
            ["c"] = "Eddie Edwards"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.SEPARATOR
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TITLE,
            ["c"] = "Senior Programmers"
        })
    elseif Platform.isSwitch2 then
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TITLE,
            ["c"] = "Senior Nintendo Switch 2 Programmer"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TEXT,
            ["c"] = "Eddie Edwards"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.SEPARATOR
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TITLE,
            ["c"] = "Senior Programmers"
        })
    else
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TITLE,
            ["c"] = "Senior Programmers"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.TEXT,
            ["c"] = "Eddie Edwards"
        })
    end
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "J\195\169r\195\180me Torche"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Olivier Four\195\169"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Samo Jordan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Programmers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bao-Anh Dang-Vu"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bojan Kerec"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Gino van den Bergen"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jan Dellsperger"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Laura Jenkins"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Lukas Nussbaumer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marius Hofmann"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Nicolas Wrobel"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Philipp J\195\164ger"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Travis Gesslein"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Vehicle Integrator"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Stefan Maurus"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Vehicle Integrators"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Arkadiusz Wodnicki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Christian Wachter"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Daniel Witzel"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Niklas Schumacher"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Simon Nussel"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Stephan Bongartz"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Associate Producer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Horia Serban"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Head of Art Brno"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tom\195\161\197\161 Dost\195\161l"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Vehicle Artist"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jan Egon Preiss"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Character Artists"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Roman Pelypenko"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Head of Outsourcing"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Siddhant Patni"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Technical Artists"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Evgeniy Zaitsev"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marta Stolarz"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Artists"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Alberto L\195\179pez Toledo"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Anton Miroshnychenko"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Arthur Franchitto"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Carlo Tosini"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Daniel Beyer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Felipe Juste"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Florian Busse"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Gabriel Hubli"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ivan Stanchev"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jakub Havel"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jakub Valehrach"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jan Dobrovoln\195\189"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "J\195\161n Ohajsk\195\189"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jozef Rolincin"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Justin Mitrache"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Katarzyna Krzyczkowska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kenan Jusic"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kevin Ellersiek"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mahdi Dehghani"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maksim Povstugar"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maria Panfilova"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Miroslav Halfar"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maximilian Fr\195\182mter"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Natalia Tkach"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Oleksandr Pelypenko"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Philipp K\195\182rber"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Radek \197\160vec"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Rahul Narode"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ra\195\186l Arencibia"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Reinaldo Artidiello"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "\197\160t\196\155p\195\161n Ba\197\153ina"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Thomas Flachs"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tom\195\161\197\161 Protivansk\195\189"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Vanessa Weidmann"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Vilen Saatsazov"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Vladyslav Vershytskyi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Graphic Designer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Sandra Meier"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Graphic Designers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Evelyn Eismann"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Katrin Huber"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mariana Borsari"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Michael Karg"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Audio Designer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Nils Heine"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Audio Designers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Andr\195\169 Sousa"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "QA Analysts"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Adrien Br\195\188llmann"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Benjamin Neu\195\159inger"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Davide Nicol\195\178 Bertossio"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dominika Wojtulewicz"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jana Stephan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kacper Walczak"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "L\195\169o Carrier"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Lo\195\175ck Ru\195\159"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marcel Renke"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marian Kysel"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mateusz Dziuba"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Oliver Kraus"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Petr Ochonsk\195\189"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mario Vortkamp"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Oliwier Ilin"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Vendula Toma\197\136ov\195\161"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Head of Publishing"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Boris Stefan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Head of Marketing & PR"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Martin Rabl"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "PR Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Wolfgang Ebert"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Content Marketing Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dennis Reisdorf"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Social Media & Brand Content Specialist"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "J\195\182rg Koonen"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Release Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Carlo Sarti"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Distribution Operations Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Anna Ru\195\159"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Publishing Assistant"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Darren Cahill"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Account Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Martin Seidel"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Technical Projects Coordinator"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jan-Hendrik Pfitzner"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Community Managers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Christoph Stumpfer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kermit Ball"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Benjamin Galla"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Lars Malcharek"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Customer Support Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Christofer Zoltan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Customer Support Representatives"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Detlef B\195\182vers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Nicholas Frazier"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Web Developers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Fabian Seitz"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marten Boessenkool"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Miroslav Mina\197\153\195\173k"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Lead Video Artist"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Michael Schraut"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Video Artist"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marco Riccardi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Daniel Walker"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Event Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Claas Eilermann"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Event Technician"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jonas Luh"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Simao Ramos"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "HR Representative"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Petra Erlbacher"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Office Managers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ad\195\169la \197\160trajtov\195\161"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Chodon F\195\188rer-Rikyog"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jennifer Dradrach"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Characters Voices"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Brian Burgess (Grandpa Walter)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Simao Ramos (David)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Cari Sholtens (Katie)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Greg Gidney (Noah)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Anthony Proctor (Helper Ben)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "John Kennard (Alasdair)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Characters Writers"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dennis Reisdorf (Grandpa Walter, David)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Erell Le Drezen (Katie)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Lukas Schreiner (Noah, Helper Ben)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jana Stephan (Helper Ben)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Lena Falkenhagen (Guided Tour)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jennifer Dradrach (Integration)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Radio & Music"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Audio Network GmbH"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Music Composer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mike Dwyer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Co-Publisher Japan/Asia"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "SEGA CORPORATION"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Partner Relationship"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Takako Takusagawa"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Shun Takakuwa"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tomoaki Ishidao"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tsekin Lai"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ke Liang"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Sandy Lig"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Project Management"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bing Lyu"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mio Yoshiba"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Yoshiaki Yamazaki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Operations"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Makoto Ito"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Susumu Ookoshi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Yuki Sumida"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Weichen Lu"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Product Marketing"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maika Nakasone"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Hiori Masuda"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tsuguharu Ishihara"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Hiroko Karube"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Masaya Santo"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "PR + Publicity"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Chihiro Miki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Keiko Yoshie"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ai Ogata"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Nana Yamaguchi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tetsuhiro Kohira"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Rena Sakai"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Siyi Xiang"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Emi Shiobara"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Japan Sales"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Katsutoshi Memezawa"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Tomohiko Hayashi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Shuto Kobayashi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Junichiro Suzuki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Yusuke Ohashi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Keiichi Oshima"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Toshiyuki Tanaka"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Masahiro Tanaka"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Shinya Oosaki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Field Crew Service Co.,Ltd."
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Asia Sales"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Yoshinori Akiyama"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Takeyuki Iso"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kousuke Uenaka"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Youichiro Shimada"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Yuta Tamagami"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Yaoxuan Bai"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Melody Law Qui-Yi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Hiroki Nagashima"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "External QA"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Testronic"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Chief Services Officer"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Erik Hittenhausen"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Director of Operations"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Stephan Herbig"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Business Development Account Director"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "El\197\188bieta Pustu\197\130"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Senior QA Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Pawe\197\130 Ko\197\130nierzak"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "QA Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Klaudia Mower"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Pawe\197\130 Marciniak"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Functionality QA"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "QA Project Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Sebastian Kurek"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "QA Project Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Micha\197\130 \197\154widzi\197\132ski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Associate QA Project Leads"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dawid Szeliga"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Functionality QA Analysts"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maciej Jarczewski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Pawe\197\130 Pielech"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Functionality QA Senior Technicians"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bartosz Kryszan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Joshua De\226\128\153Ath"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Functionality QA Technicians"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bart\197\130omiej Drozd"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bartosz Cie\197\155lak"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Cosmin-George Pandichi"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Hayam Mansour"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jainal Panchal"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kamil Kaczor"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Krzysztof Goliniewski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maciej Powa\197\130a"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Magdalena Dro\197\188y\197\132ska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Maksymilian Zwirkowski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Micha\197\130 Pielech"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Pawe\197\130 Bara\197\132ski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Rafa\197\130 S\197\130owik"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ryszard Bartocha"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Sebastian Fuchs"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compliance & Compatibility QA"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compliance and Compatibility Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Iwona Szarzy\197\132ska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Senior Compliance and Compatibility Project Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ma\197\130gorzata Twarogal"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compliance QA"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compliance QA Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Micha\197\130 Rad\197\130owski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Associate Compliance QA Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Adrian Strzelecki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dorian Geisler"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compliance QA Analyst"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Agata Dylak-Str\196\133k"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Alicja Nosecka"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Aneta Majek"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jakub Neyman"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compliance QA Technicians"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Agata Cywi\197\132ska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Anandha Mohanan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Damian Utrata"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Ganna Nasser"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Hakan Berk Soydan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jainal Panchal"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "\197\129ukasz Seremet"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Martyna Jurczy\197\132ska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Nikadzim Runtsou"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Pax Kibart"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Sanjeet Earnest"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Sodiq Adefila"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "PC Compatibility QA"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Associate Compatibility QA Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Micha\197\130 Soral"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compatibility QA Analyst"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "\197\129ukasz \197\129aci\197\132ski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Compatibility QA Technicians"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Bart\197\130omiej Stajkowski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Brine Mukombachoto"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dominik Krawczyk"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Haran Dev Murugan"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Localisation QA"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Senior Localisation QA Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Valentina Mollica"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Localisation QA Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jouhaina Ramy"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Localisation QA Project Manager"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Krzysztof Orlikowski"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Localisation QA Lead"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jamie Kelly-Warwick"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Senior Localisation QA Technicians"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Anthony Brian Yuen"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Charlotte Cameron"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Dennis Born"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jefta de Cock"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Keiko Naito"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Morten \195\152stergaard"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Piotr Rokitnicki"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Localisation QA Technicians"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "\195\129lvaro Saavedra Jeno"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Brice Jos\195\169 Fajardo Ory"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Cristina Baleanu"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Davide Fanni"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Jaehun Bae"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Kan Cheng"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Katarzyna Maciejewska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marcela Ostrochovska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Marilia Stieven Sonza"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "P\195\161l Veres Kov\195\161cs"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Roksolana Krushenytska"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Stephen Bubenheim"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2003-2024 GIANTS Software GmbH"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Farming Simulator"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "GIANTS Software and its logos are trademarks"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "or registered trademarks of GIANTS Software"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "All rights reserved."
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "All manufacturers, vehicles, machines,"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "equipment, names, brands, and"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "associated imagery featured in this game"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "in some cases include trademarks and/or"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "copyrighted materials of their"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "respective owners. The vehicles,"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "machines, and equipment in this game"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "may be different from the actual ones"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "in shapes, colors and performance."
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Aprilia\194\174 Official Licensee. Aprilia\194\174 is a registered"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "trademark owned by Piaggio & C. S.p.A. and"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "used under license by GIANTS Software GmbH."
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Ape\194\174 Official Licensee. Ape\194\174 is a registered"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "trademark owned by Piaggio & C. S.p.A. and"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "used under license by GIANTS Software GmbH."
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "The VOLVO trademarks (word and device),"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "other related trademarks, if applicable, "
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "and the Volvo designs are licensed by"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "the AB Volvo Group."
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    if not (GS_PLATFORM_XBOX or GS_IS_MOBILE_VERSION) then
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = g_i18n:getText("ui_copyrightSymbol") .. " 2024 Sony Interactive Entertainment LLC."
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "\"PlayStation Family Mark\", \"PlayStation\","
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "\"PS5 logo\", \"PS5\","
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "\"PlayStation Shapes Logo\" and \"Play Has No Limits\""
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "are registered trademarks or trademarks of"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "Sony Interactive Entertainment Inc."
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = ""
        })
    end
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Uses Lua"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1994-2024 Lua.org, PUC-Rio"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Uses Luau"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2019-2024 Roblox Corporation"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Uses Ogg Vorbis and Theora"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1994-2024 Xiph.Org Foundation"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    if GS_PLATFORM_PC then
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "Uses FLAC"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2000-2009, Josh Coalson"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2011-2024, Xiph.Org Foundation"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = ""
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.SEPARATOR
        })
    end
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Uses Zlib"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1995-2024 Jean-loup Gailly"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "and Mark Adler"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "This software is based in part on"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "the work of the Independent JPEG Group"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1991-2024 Independent JPEG Group"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Uses Opus Interactive Audio Codec"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2001-2011 Xiph.Org, Skype Limited,"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Octasic, Jean-Marc Valin, Timothy B. Terriberry, CSIRO, Gregory Maxwell, Mark Borgerding,"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Erik de Castro Lopo"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    if GS_PLATFORM_PC and not GS_IS_MSSTORE_VERSION then
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "Uses Curl"
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1996-2024, Daniel Stenberg, daniel@haxx.se, and many contributors, see the THANKS file."
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.DISCLAIMER,
            ["c"] = ""
        })
        table.insert(creditsTexts, {
            ["t"] = CreditsScreen.SEPARATOR
        })
    end
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Uses VHACD"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2011, Khaled Mamou (kmamou at gmail dot com)"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.DISCLAIMER,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = "Special Thanks to"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Martin B\195\164rwolf"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Mike Pall"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Andr\195\169s Villegas"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Brian Burgess"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.SEPARATOR
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TEXT,
        ["c"] = "Thanks for playing!"
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = {
        ["t"] = CreditsScreen.TITLE,
        ["c"] = ""
    }
    table.insert(creditsTexts, i)
    local i = #self.creditsPlaceholder.elements
    for i = i, 1, -1 do
        self.creditsPlaceholder.elements[i]:delete()
    end
    self.creditsElements = {}
    for _, creditsElem in pairs(creditsTexts) do
        self.currentCreditsText = creditsElem.c
        local newCreditsElem = nil
        if creditsElem.t == CreditsScreen.TITLE then
            newCreditsElem = self.creditsTitleElement:clone(self.creditsPlaceholder)
            newCreditsElem:updateSize()
            newCreditsElem:setText(creditsElem.c)
        elseif creditsElem.t == CreditsScreen.TEXT then
            newCreditsElem = self.creditsTextElement:clone(self.creditsPlaceholder)
            newCreditsElem:setText(creditsElem.c)
        elseif creditsElem.t == CreditsScreen.DISCLAIMER then
            newCreditsElem = self.creditsDisclaimerElement:clone(self.creditsPlaceholder)
            newCreditsElem:setText(creditsElem.c)
        end
        if newCreditsElem ~= nil then
            newCreditsElem:setAlpha(0)
            table.insert(self.creditsElements, newCreditsElem)
        end
    end
    self.creditsEndY = self.creditsPlaceholder.size[2] + self.creditsPlaceholder:invalidateLayout(true)
end
function CreditsScreen:updateTheme()
    local filename = Platform.gameLogos[g_languageShort]
    if filename == nil then
        filename = Platform.gameLogos.en
    end
    if self.logo ~= nil then
        self.logo:setImageFilename(filename)
    end
end
function CreditsScreen:onCareerClick(element)
    self:changeScreen(MainScreen)
    FocusManager:setFocus(g_mainScreen.careerButton)
    g_mainScreen:onCareerClick(element)
end
function CreditsScreen:onAchievementsClick(element)
    self:changeScreen(MainScreen)
    FocusManager:setFocus(g_mainScreen.achievementsButton)
    g_mainScreen:onAchievementsClick(element)
end
function CreditsScreen.onChangeMobileSettingsClick(_, element)
    g_mainScreen:onChangeMobileSettingsClick(element)
end