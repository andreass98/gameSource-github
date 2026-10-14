VehicleMaterialManager = {}
VehicleMaterialManager.DEFAULT_TEMPLATES_FILENAME = "data/shared/detailLibrary/materialTemplates.xml"
VehicleMaterialManager.DEFAULT_BRAND_TEMPLATES_FILENAME = "data/shared/brandMaterialTemplates.xml"
VehicleMaterialManager.xmlSchema = nil
VehicleMaterialManager.NUM_BITS_TEMPLATE = 16
VehicleMaterialManager.MAX_TEMPLATE_INDEX = 2 ^ VehicleMaterialManager.NUM_BITS_TEMPLATE - 1
source("dataS/scripts/vehicles/VehicleMaterial.lua")
local VehicleMaterialManager_mt = Class(VehicleMaterialManager, AbstractManager)
function VehicleMaterialManager.new(customMt)
    -- upvalues: (copy) VehicleMaterialManager_mt
    local self = AbstractManager.new(customMt or VehicleMaterialManager_mt)
    VehicleMaterialManager.xmlSchema = XMLSchema.new("materialTemplates")
    VehicleMaterialManager.registerXMLPaths(VehicleMaterialManager.xmlSchema, "templates")
    return self
end
function VehicleMaterialManager:initDataStructures()
    self.materialTemplates = {}
    self.materialTemplatesByName = {}
    self.modMaterialTemplatesToLoad = {}
end
function VehicleMaterialManager:loadMapData(_, _, _)
    self:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_TEMPLATES_FILENAME)
    self:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_BRAND_TEMPLATES_FILENAME)
    local i = #self.modMaterialTemplatesToLoad
    for i = i, 1, -1 do
        local modMaterialTemplate = self.modMaterialTemplatesToLoad[i]
        local xmlFile = XMLFile.load("ModFile", modMaterialTemplate.xmlFilename, g_modDescSchema)
        if xmlFile ~= nil then
            self:loadMaterialTemplatesFromXML(xmlFile, modMaterialTemplate.key, modMaterialTemplate.baseDirectory, modMaterialTemplate.customEnvironment, "calibratedPaint")
            xmlFile:delete()
        end
        table.remove(self.modMaterialTemplatesToLoad, i)
    end
end
function VehicleMaterialManager:addModMaterialTemplatesToLoad(xmlFilename, key, baseDirectory, customEnvironment)
    table.insert(self.modMaterialTemplatesToLoad, {
        ["xmlFilename"] = xmlFilename,
        ["key"] = key,
        ["baseDirectory"] = baseDirectory,
        ["customEnvironment"] = customEnvironment
    })
end
function VehicleMaterialManager:loadMaterialTemplates(xmlFilename, baseDirectory, customEnvironment)
    local xmlFile = XMLFile.load("templates", xmlFilename, VehicleMaterialManager.xmlSchema)
    if xmlFile ~= nil then
        self:loadMaterialTemplatesFromXML(xmlFile, "templates", baseDirectory, customEnvironment)
        xmlFile:delete()
    end
end
function VehicleMaterialManager:loadMaterialTemplatesFromXML(xmlFile, key, baseDirectory, customEnvironment, parentTemplateDefault)
    parentTemplateDefault = xmlFile:getValue(key .. "#parentTemplateDefault", parentTemplateDefault)
    xmlFile:iterate(key .. ".template", function(_, templateKey)
        -- upvalues: (copy) xmlFile, (copy) customEnvironment, (ref) parentTemplateDefault, (copy) self, (copy) baseDirectory
        local name = xmlFile:getValue(templateKey .. "#name")
        if name == nil then
            Logging.xmlWarning(xmlFile, "Missing name attribute for \'%s\'", templateKey)
            return
        else
            local parentName
            if customEnvironment == nil then
                parentName = string.upper(name)
            else
                parentName = string.upper(customEnvironment .. "." .. name)
            end
            local parentName = xmlFile:getValue(templateKey .. "#parentTemplate", parentTemplateDefault)
            local parentTemplate = nil
            if parentName ~= nil then
                parentTemplate = self.materialTemplatesByName[string.upper(parentName)]
                if parentTemplate == nil then
                    Logging.xmlWarning(xmlFile, "Unable to find parent template \'%s\' for \'%s\'", parentName, templateKey)
                    return
                end
            end
            local materialTemplate = self.materialTemplatesByName[parentName]
            local materialTemplate = materialTemplate == nil and {} or materialTemplate
            materialTemplate.name = parentName
            materialTemplate.parentTemplate = parentTemplate or materialTemplate
            materialTemplate.customEnvironment = customEnvironment
            local brandName = xmlFile:getValue(templateKey .. "#brand")
            if brandName ~= nil then
                materialTemplate.brand = g_brandManager:getBrandByName(brandName)
                if materialTemplate.brand == nil then
                    Logging.xmlWarning(xmlFile, "Unknown brand \'%s\' defined in material template \'%s\'", brandName, templateKey)
                end
            end
            materialTemplate.titleL10N = xmlFile:getValue(templateKey .. "#title")
            materialTemplate.colorScale = xmlFile:getValue(templateKey .. "#colorScale", nil, true)
            materialTemplate.smoothnessScale = xmlFile:getValue(templateKey .. "#smoothnessScale")
            materialTemplate.metalnessScale = xmlFile:getValue(templateKey .. "#metalnessScale")
            materialTemplate.clearCoatSmoothness = xmlFile:getValue(templateKey .. "#clearCoatSmoothness")
            materialTemplate.clearCoatIntensity = xmlFile:getValue(templateKey .. "#clearCoatIntensity")
            materialTemplate.porosity = xmlFile:getValue(templateKey .. "#porosity")
            materialTemplate.detailDiffuse = xmlFile:getValue(templateKey .. "#detailDiffuse")
            if materialTemplate.detailDiffuse ~= nil then
                materialTemplate.detailDiffuse = Utils.getFilename(materialTemplate.detailDiffuse, baseDirectory)
                if not textureFileExists(materialTemplate.detailDiffuse) then
                    Logging.xmlWarning(xmlFile, "Unable to find detail texture \'%s\' in \'%s\'", materialTemplate.detailDiffuse, templateKey)
                    materialTemplate.detailDiffuse = nil
                end
            end
            if materialTemplate.detailDiffuse == nil and materialTemplate.parentTemplate.detailDiffuse == nil then
                Logging.xmlWarning(xmlFile, "Missing detail diffuse texture for \'%s\'", templateKey)
                return
            else
                materialTemplate.detailNormal = xmlFile:getValue(templateKey .. "#detailNormal")
                if materialTemplate.detailNormal ~= nil then
                    materialTemplate.detailNormal = Utils.getFilename(materialTemplate.detailNormal, baseDirectory)
                    if not textureFileExists(materialTemplate.detailNormal) then
                        Logging.xmlWarning(xmlFile, "Unable to find detail texture \'%s\' in \'%s\'", materialTemplate.detailNormal, templateKey)
                        materialTemplate.detailNormal = nil
                    end
                end
                if materialTemplate.detailNormal == nil and materialTemplate.parentTemplate.detailNormal == nil then
                    Logging.xmlWarning(xmlFile, "Missing detail normal texture for \'%s\'", templateKey)
                    return
                else
                    materialTemplate.detailSpecular = xmlFile:getValue(templateKey .. "#detailSpecular")
                    if materialTemplate.detailSpecular ~= nil then
                        materialTemplate.detailSpecular = Utils.getFilename(materialTemplate.detailSpecular, baseDirectory)
                        if not textureFileExists(materialTemplate.detailSpecular) then
                            Logging.xmlWarning(xmlFile, "Unable to find detail texture \'%s\' in \'%s\'", materialTemplate.detailSpecular, templateKey)
                            materialTemplate.detailSpecular = nil
                        end
                    end
                    if materialTemplate.detailSpecular == nil and materialTemplate.parentTemplate.detailSpecular == nil then
                        Logging.xmlWarning(xmlFile, "Missing detail specular texture for \'%s\'", templateKey)
                    else
                        table.insert(self.materialTemplates, materialTemplate)
                        self.materialTemplatesByName[parentName] = materialTemplate
                    end
                end
            end
        end
    end)
end
function VehicleMaterialManager:getMaterialTemplateByName(name, customEnvironment)
    if name == nil then
        return nil
    end
    if customEnvironment ~= nil then
        local template = self.materialTemplatesByName[string.upper(customEnvironment .. "." .. name)]
        if template ~= nil then
            return template
        end
    end
    return self.materialTemplatesByName[string.upper(name)]
end
function VehicleMaterialManager:getMaterialTemplateColorByName(name, customEnvironment)
    if name ~= nil then
        local materialTemplate = self:getMaterialTemplateByName(string.upper(name), customEnvironment)
        if materialTemplate ~= nil and materialTemplate.colorScale ~= nil then
            return {
                materialTemplate.colorScale[1],
                materialTemplate.colorScale[2],
                materialTemplate.colorScale[3],
                0
            }
        end
    end
    return nil
end
function VehicleMaterialManager:getMaterialTemplateColorAndTitleByName(name, customEnvironment)
    if name ~= nil then
        local materialTemplate = self:getMaterialTemplateByName(string.upper(name), customEnvironment)
        if materialTemplate ~= nil then
            local title = nil
            if materialTemplate.brand ~= nil then
                title = materialTemplate.brand.title
            end
            if materialTemplate.titleL10N ~= nil then
                title = (title == nil and "" or title .. " ") .. g_i18n:convertText(materialTemplate.titleL10N, materialTemplate.customEnvironment)
            end
            if materialTemplate.colorScale == nil then
                return { 1, 1, 1 }, title
            else
                return table.clone(materialTemplate.colorScale), title
            end
        end
    end
    return nil, nil
end
function VehicleMaterialManager:getMaterialTemplateIndexByName(name)
    if name ~= nil then
        name = string.upper(name)
        for i, materialTemplate in ipairs(self.materialTemplates) do
            if materialTemplate.name == name then
                return i
            end
        end
    end
    return 1
end
function VehicleMaterialManager:getMaterialTemplateNameByIndex(index)
    return (self.materialTemplates[index] or self.materialTemplates[1]).name
end
function VehicleMaterialManager.getMaterialTemplateFinish(_, materialTemplateName)
    local isMetallic = false
    local isMat = false
    if materialTemplateName == nil then
        return isMetallic, isMat
    end
    local materialTemplateNameLower = string.lower(materialTemplateName)
    return (materialTemplateNameLower:contains("silver") or (materialTemplateNameLower:contains("copper") or (materialTemplateNameLower:contains("gold") or (materialTemplateNameLower:contains("bronze") or (materialTemplateNameLower:contains("chrome") or materialTemplateNameLower:contains("metallic")))))) and true or isMetallic, materialTemplateNameLower:contains("matpaint") and true or isMat
end
function VehicleMaterialManager.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#id", "File Identifier")
    schema:register(XMLValueType.STRING, basePath .. "#name", "File Name")
    schema:register(XMLValueType.STRING, basePath .. "#parentTemplateDefault", "Name of default parent template")
    schema:register(XMLValueType.STRING, basePath .. "#parentTemplateFilename", "Path to parent template file")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#name", "Name of template")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#title", "Name of the color to display in the shop")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#description", "Descrpition text of the template")
    schema:register(XMLValueType.INT, basePath .. ".template(?)#usage", "Usage of the color")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#parentTemplate", "Name of parent template", "templates#parentTemplateDefault")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#brand", "Brand identifier")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".template(?)#colorScale", "Color values (sRGB)")
    schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#smoothnessScale")
    schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#metalnessScale")
    schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#clearCoatSmoothness")
    schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#clearCoatIntensity")
    schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#porosity")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#category", "Category name (Used by DCC Tool)")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#iconFilename", "Icon filename (Used by DCC Tool)")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#detailDiffuse", "Detail diffuse texture")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#detailNormal", "Detail normal texture")
    schema:register(XMLValueType.STRING, basePath .. ".template(?)#detailSpecular", "Detail specular texture")
    schema:register(XMLValueType.STRING, basePath .. ".template(?).colorScan#filename", "Path to scan reference")
    schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelR", "Calibrate red channel", true)
    schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelG", "Calibrate green channel", true)
    schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelB", "Calibrate blue channel", true)
    schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelSmoothness", "Calibrate smoothness", true)
    schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelMetalness", "Calibrate metalness", true)
end
g_vehicleMaterialManager = VehicleMaterialManager.new()