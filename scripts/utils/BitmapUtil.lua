BitmapUtil = {}
BitmapUtil.FORMAT = {}
BitmapUtil.FORMAT.BITMAP = 0
BitmapUtil.FORMAT.GREYMAP = 1
BitmapUtil.FORMAT.PIXELMAP = 2
BitmapUtil.FORMAT_TO_PNM = {
    [BitmapUtil.FORMAT.BITMAP] = {
        ["extension"] = "pbm",
        ["getHeader"] = function(width, height, _)
            return string.format("P4\n%d %d\n", width, height)
        end,
        ["getPixel"] = function(pixelTable)
            return string.format("%c", pixelTable[1])
        end
    },
    [BitmapUtil.FORMAT.GREYMAP] = {
        ["extension"] = "pgm",
        ["getHeader"] = function(width, height, maxBrightness)
            return string.format("P5\n%d %d\n%d\n", width, height, maxBrightness)
        end,
        ["getPixel"] = function(pixelTable)
            return string.format("%c", pixelTable[1])
        end
    },
    [BitmapUtil.FORMAT.PIXELMAP] = {
        ["extension"] = "ppm",
        ["getHeader"] = function(width, height, maxBrightness)
            return string.format("P6\n%d %d\n%d\n", width, height, maxBrightness)
        end,
        ["getPixel"] = function(pixelTable)
            return string.format("%c%c%c", pixelTable[1], pixelTable[2], pixelTable[3])
        end
    }
}
function BitmapUtil.writeBitmapToFile(pixels, width, height, filepath, imageFormat)
    local pnmFormat = BitmapUtil.FORMAT_TO_PNM[imageFormat]
    if pnmFormat == nil then
        Logging.error("Invalid image format \'%s\'. Use one of BitmapUtil.FORMAT", imageFormat)
        return false
    end
    local file = string.format("%s.%s", filepath, pnmFormat.extension or "pnm")
    local file = createFile(file, FileAccess.WRITE)
    if file == 0 then
        Logging.error("BitmapUtil.writeBitmapToFile(): Unable to create file \'%s\'", file)
        return false
    end
    fileWrite(file, pnmFormat.getHeader(width, height, 255))
    local pixelsToWrite = {}
    local pixelIndex = 1
    for pixelIndex = pixelIndex, #pixels do
        pixelsToWrite[#pixelsToWrite + 1] = pnmFormat.getPixel(pixels[pixelIndex])
        if pixelIndex % 1025 == 0 then
            fileWrite(file, table.concat(pixelsToWrite))
            table.clear(pixelsToWrite)
        end
    end
    if #pixelsToWrite > 0 then
        fileWrite(file, concatFunc(pixelsToWrite))
    end
    delete(file)
    Logging.info("Wrote bitmap (width=%d, height=%d) to \'%s\'", width, height, file)
    return true
end
function BitmapUtil.writeBitmapToFileFromIterator(iterator, width, height, filepath, imageFormat)
    local pnmFormat = BitmapUtil.FORMAT_TO_PNM[imageFormat]
    if pnmFormat == nil then
        Logging.error("Invalid image format \'%s\'. Use one of BitmapUtil.FORMAT", imageFormat)
        return false
    end
    local file = string.format("%s.%s", filepath, pnmFormat.extension or "pnm")
    local file = createFile(file, FileAccess.WRITE)
    if file == 0 then
        Logging.error("BitmapUtil.writeBitmapToFileFromIterator(): Unable to create file \'%s\'", file)
        return false
    end
    fileWrite(file, pnmFormat.getHeader(width, height, 255))
    local pixelsToWrite = {}
    local pixelIndex = 1
    for pixel in iterator() do
        pixelsToWrite[#pixelsToWrite + 1] = pnmFormat.getPixel(pixel)
        if pixelIndex % 1025 == 0 then
            fileWrite(file, table.concat(pixelsToWrite))
            table.clear(pixelsToWrite)
        end
        pixelIndex = pixelIndex + 1
    end
    if #pixelsToWrite > 0 then
        fileWrite(file, concatFunc(pixelsToWrite))
    end
    delete(file)
    Logging.info("Wrote bitmap (width=%d, height=%d) to \'%s\'", width, height, file)
    return true
end