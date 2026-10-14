GuiProfile = {}
local GuiProfile_mt = Class(GuiProfile)
function GuiProfile.new(profiles, traits)
    -- upvalues: (copy) GuiProfile_mt
    local self = setmetatable({}, GuiProfile_mt)
    self.values = {}
    self.name = ""
    self.profiles = profiles
    self.traits = traits
    self.parent = nil
    return self
end
function GuiProfile:loadFromXML(xmlFile, key, presets, isTrait, isVariant)
    local name = getXMLString(xmlFile, key .. "#name")
    if name == nil then
        Logging.xmlWarning(xmlFile, "Missing name for a profile in XML file %s at path %s", getXMLFilename(xmlFile), key)
        return false
    end
    self.name = name
    self.isTrait = isTrait or false
    self.parent = getXMLString(xmlFile, key .. "#extends")
    self.isVariant = isVariant
    if self.parent == self.name then
        error("Profile " .. name .. " extends itself")
    end
    if not isTrait then
        local traitsStr = getXMLString(xmlFile, key .. "#with")
        if traitsStr ~= nil then
            local traitNames = string.split(string.trim(traitsStr), " ")
            for i, traitName in ipairs(traitNames) do
                local trait = self.traits[traitName]
                if trait == nil then
                    Logging.xmlWarning(xmlFile, "Trait-profile \'%s\' not found for trait \'%s\' at \'%s\'", traitName, self.name, key)
                else
                    for traitValueName, value in pairs(trait.values) do
                        self.values[traitValueName] = value
                    end
                end
            end
        end
    end
    local traitNames = 0
    local i = 0
    for i = i, getXMLNumOfChildren(xmlFile, key) - 1 do
        local i = getXMLElementName(xmlFile, string.format("%s.*(%i)", key, i))
        local traitName = key .. string.format(".%s(0)#value", i)
        if i == "Value" then
            i = getXMLString(xmlFile, key .. string.format(".Value(%i)#name", traitNames))
            traitName = key .. string.format(".Value(%i)#value", traitNames)
            traitNames = traitNames + 1
            Logging.xmlWarning(xmlFile, "Gui profile \'%s\' still uses old format, please convert it to the new one", i)
        end
        local trait = getXMLString(xmlFile, traitName)
        if i == nil or (trait == nil or i == "Variant") then
            break
        end
        if trait:startsWith("$preset_") then
            local preset = string.gsub(trait, "$preset_", "")
            if presets[preset] == nil then
                Logging.xmlWarning(xmlFile, "Preset \'%s\' it profile \'%s\' at \'%s\' is not defined", preset, name, traitName)
            else
                trait = presets[preset]
            end
        end
        self.values[i] = trait
    end
    return true
end
function GuiProfile:getValue(name, default)
    if self.values[name .. g_baseUIPostfix] ~= nil and self.values[name .. g_baseUIPostfix] ~= "nil" then
        return self.values[name .. g_baseUIPostfix]
    end
    if self.values[name] ~= nil and self.values[name] ~= "nil" then
        return self.values[name]
    end
    if self.parent ~= nil then
        local parentProfile
        if self.isVariant then
            parentProfile = self.profiles[self.parent]
        else
            parentProfile = g_gui:getProfile(self.parent)
        end
        if parentProfile ~= nil and parentProfile ~= "nil" then
            return parentProfile:getValue(name, default)
        end
        Logging.warning("Parent-profile \'%s\' not found for profile \'%s\'", self.parent, self.name)
    end
    return default
end
function GuiProfile:getBool(name, default)
    local value = self:getValue(name)
    if value ~= nil and value ~= "nil" then
        default = string.lower(value) == "true"
    end
    return default
end
function GuiProfile:getNumber(name, default)
    local value = self:getValue(name)
    if value ~= nil and value ~= "nil" then
        default = tonumber(value)
    end
    return default
end