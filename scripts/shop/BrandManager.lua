Brand = nil
BrandManager = {}
local BrandManager_mt = Class(BrandManager, AbstractManager)
function BrandManager.new(customMt)
    -- upvalues: (copy) BrandManager_mt
    local self = AbstractManager.new(customMt or BrandManager_mt)
    addConsoleCommand("gsBrandUsageList", "Prints a list of all used brands", "consoleCommandBrandUsageList", self)
    return self
end
function BrandManager:initDataStructures()
    self.numOfBrands = 0
    self.nameToIndex = {}
    self.nameToBrand = {}
    self.indexToBrand = {}
    Brand = self.nameToIndex
end
function BrandManager:loadMapData(_)
    BrandManager:superClass().loadMapData(self)
    local xmlFile = XMLFile.load("brandsXML", "dataS/brands.xml")
    for _, brandKey in xmlFile:iterator("brands.brand") do
        local name = xmlFile:getString(brandKey .. "#name")
        local title = xmlFile:getString(brandKey .. "#title")
        local image = xmlFile:getString(brandKey .. "#image")
        local imageShopOverview = xmlFile:getString(brandKey .. "#imageShopOverview")
        local imageOffset = xmlFile:getFloat(brandKey .. "#imageOffset")
        if title ~= nil and string.startsWith(title, "$l10n_") then
            title = g_i18n:getText(title:sub(7))
        end
        self:addBrand(name, title, image, "", false, imageShopOverview, imageOffset)
    end
    xmlFile:delete()
    return true
end
function BrandManager:addBrand(name, title, imageFilename, baseDir, isMod, imageShopOverview, imageOffset)
    if name == nil or name == "" then
        Logging.warning("Could not register brand. Name is missing or empty!")
        return false
    end
    if title == nil or title == "" then
        Logging.warning("Could not register brand \'%s\'. Title is missing or empty!", name)
        return false
    end
    if imageFilename == nil or imageFilename == "" then
        Logging.warning("Could not register brand \'%s\'. Image is missing or empty!", name)
        return false
    end
    if baseDir == nil then
        Logging.warning("Could not register brand \'%s\'. Base directory not defined!", name)
        return false
    end
    if imageShopOverview == nil then
        imageShopOverview = imageFilename
    end
    local brand = string.upper(name)
    if not ClassUtil.getIsValidIndexName(brand) then
        Logging.warning("Invalid brand name \'" .. tostring(brand) .. "\'! Only capital letters allowed!")
        return nil
    end
    if self.nameToIndex[brand] ~= nil then
        return nil
    end
    self.numOfBrands = self.numOfBrands + 1
    self.nameToIndex[brand] = self.numOfBrands
    local brand = {
        ["index"] = self.numOfBrands,
        ["name"] = brand,
        ["image"] = Utils.getFilename(imageFilename, baseDir),
        ["imageShopOverview"] = Utils.getFilename(imageShopOverview, baseDir),
        ["title"] = title,
        ["isMod"] = isMod,
        ["imageOffset"] = imageOffset or 0
    }
    self.nameToBrand[brand] = brand
    self.indexToBrand[self.numOfBrands] = brand
    return brand
end
function BrandManager:getBrandByIndex(brandIndex)
    if brandIndex == nil then
        return nil
    else
        return self.indexToBrand[brandIndex]
    end
end
function BrandManager:getBrandIconByIndex(brandIndex)
    if brandIndex == nil or self.indexToBrand[brandIndex] == nil then
        return nil
    else
        return self.indexToBrand[brandIndex].image
    end
end
function BrandManager:getBrandByName(brandName)
    if brandName == nil then
        return nil
    else
        return self.nameToBrand[string.upper(brandName)]
    end
end
function BrandManager:getBrandIndexByName(brandName)
    if brandName == nil then
        return nil
    end
    if not ClassUtil.getIsValidIndexName(brandName) then
        Logging.warning("Invalid brand name \'" .. brandName .. "\'! Only capital letters and underscores allowed. Using Lizard instead.")
        return Brand.LIZARD
    end
    local brandIndex = self.nameToIndex[string.upper(brandName)]
    if brandIndex ~= nil then
        return brandIndex
    end
    local bestMatch = Utils.getClosestMatchingString(brandName, table.toList(self.nameToBrand), 3)
    local suggestions = bestMatch and string.format(" Did you mean \'%s\'?", bestMatch) or ""
    Logging.warning("\'%s\' is an unknown brand!%s Using \'LIZARD\' instead!", brandName, suggestions)
    return Brand.LIZARD
end
function BrandManager:consoleCommandBrandUsageList()
    local storeItems = g_storeManager:getItems()
    local usedBrands = {}
    local unusedBrands = {}
    for brandIndex, brand in pairs(self.indexToBrand) do
        local found = false
        for _, alwaysUsedBrand in ipairs({
            "BKT",
            "CONTINENTAL",
            "ELTEN",
            "LELY",
            "MICHELIN",
            "MITAS",
            "NOKIAN",
            "OLOFSFORS",
            "STRAUSS",
            "TRELLEBORG"
        }) do
            if alwaysUsedBrand == brand.name then
                table.insert(usedBrands, brand.title)
                found = true
                break
            end
        end
        if not found then
            for _, alwaysUsedBrand in ipairs(storeItems) do
                if alwaysUsedBrand.brandIndex == brandIndex then
                    table.insert(usedBrands, brand.title)
                    found = true
                    break
                end
            end
        end
        if not found then
            table.insert(unusedBrands, brand.title)
        end
    end
    table.sort(usedBrands)
    table.sort(unusedBrands)
    local usedBrandList = table.concat(usedBrands, "\n")
    local str = (("\n" .. string.format("Brands used in store items (%d):\n", #usedBrands)) .. usedBrandList) .. "\n\n\n"
    local unusedBrandList = table.concat(unusedBrands, "\n")
    local str = ((str .. string.format("Brands NOT used in store items (%d):\n", #unusedBrands)) .. unusedBrandList) .. "\n\n"
    print(str)
end
g_brandManager = BrandManager.new()