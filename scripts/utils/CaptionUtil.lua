CaptionUtil = {}
CaptionUtil.TEXTS = {}
function CaptionUtil.addText(text)
    table.insert(CaptionUtil.TEXTS, text)
    CaptionUtil.updateCaption()
    return #CaptionUtil.TEXTS
end
function CaptionUtil.setPartialText(index, text)
    if CaptionUtil.TEXTS[index] ~= nil then
        CaptionUtil.TEXTS[index] = text
    end
end
function CaptionUtil.updateCaption()
    local caption = CaptionUtil.getCaption()
    setCaption(caption)
end
function CaptionUtil.getCaption()
    return table.concat(CaptionUtil.TEXTS, " ")
end