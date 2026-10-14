ConsumableActivatable = {}
ConsumableActivatable.TYPE_TEXTS = {}
ConsumableActivatable.TYPE_TEXTS.BALE_WRAP = "action_refillBaleWrap"
ConsumableActivatable.TYPE_TEXTS.BALE_NET = "action_refillBaleNet"
ConsumableActivatable.TYPE_TEXTS.BALE_TWINE = "action_refillBaleTwine"
ConsumableActivatable.TYPE_TEXTS.RICE_SAPLINGS = "action_refillBaleTwine"
local ConsumableActivatable_mt = Class(ConsumableActivatable)
function ConsumableActivatable.new(vehicle)
    -- upvalues: (copy) ConsumableActivatable_mt
    local self = setmetatable({}, ConsumableActivatable_mt)
    self.vehicle = vehicle
    self.activateText = ""
    return self
end
function ConsumableActivatable:getIsActivatable()
    if self.vehicle:getIsActiveForInput(true) then
        for i, type in ipairs(self.vehicle.spec_consumable.types) do
            if type.consumingFillLevel == 0 then
                return true
            end
        end
    end
    return false
end
function ConsumableActivatable:run()
    for typeIndex, type in ipairs(self.vehicle.spec_consumable.types) do
        if type.consumingFillLevel == 0 then
            self.optionsTypeName = type.typeName
            self.options, self.optionToVariationIndex = g_consumableManager:getConsumableVariationsByType(type.typeName)
            local typeIndex
            OptionDialog.show(function(index)
                -- upvalues: (copy) self, (copy) typeIndex
                if index ~= nil then
                    local variationIndex = self.optionToVariationIndex[index]
                    if variationIndex ~= nil then
                        ConsumableRefillEvent.sendEvent(self.vehicle, typeIndex, variationIndex)
                    end
                end
            end, g_i18n:getText("ui_consumableSelectType"), g_i18n:getText(ConsumableActivatable.TYPE_TEXTS[type.typeName]), self.options)
        end
    end
end
function ConsumableActivatable:updateActivateText()
    for i, type in ipairs(self.vehicle.spec_consumable.types) do
        if type.consumingFillLevel == 0 then
            self.activateText = g_i18n:getText(ConsumableActivatable.TYPE_TEXTS[type.typeName])
        end
    end
end