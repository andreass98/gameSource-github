BaseMaterial = {}
function BaseMaterial.prerequisitesPresent(specializations)
    return true
end
function BaseMaterial.initSpecialization() end
function BaseMaterial.registerFunctions(vehicleType) end
function BaseMaterial.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaseMaterial)
end
function BaseMaterial:onLoad(_)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baseMaterial")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baseMaterialConfigurations", "vehicle.designColorConfigurations")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.designMaterialConfigurations", "vehicle.designColorConfigurations")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.designMaterial2Configurations", "vehicle.designColorConfigurations")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.designMaterial3Configurations", "vehicle.designColorConfigurations")
end
function BaseMaterial.registerBaseMaterialConfigurationsXMLPaths()
    Logging.error("BaseMaterial.registerBaseMaterialConfigurationsXMLPaths is not available anymore")
end