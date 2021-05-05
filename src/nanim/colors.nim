import nanovg, re, tables, strutils, nanim/logging


let colorsCache = newTable[string, Color]()

proc cacheColor(name: string, color: Color): Color {.inline.} =
  colorsCache[name] = color
  return color


proc newColor*(r, g, b, a: float = 1.0): Color {.inline.} =
  discard


let
  hexRegex = re("[#]?([0-9a-fA-F]{2})")
  rgbRegex = re("""rgb\([\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?,[\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?,[\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?\)""")
  rgbaRegex = re("""rgba\([\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?,[\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?,[\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?,[\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?\)""")


func hexToFloat(hexString: string): float {.inline.} =
  return fromHex[int](hexString).toFloat()/255.0


proc newColor*(cssString: string): Color =
  if colorsCache.hasKey(cssString):
    return colorsCache[cssString]

  let hexMatch = cssString.findAll(hexRegex)
  if len(hexMatch) == 3:
      return cacheColor(cssString, rgb(hexToFloat(hexMatch[0]),
                                       hexToFloat(hexMatch[1]),
                                       hexToFloat(hexMatch[2])))
  if len(hexMatch) >= 4:
      return cacheColor(cssString, rgba(hexToFloat(hexMatch[0]),
                                        hexToFloat(hexMatch[1]),
                                        hexToFloat(hexMatch[2]),
                                        hexToFloat(hexMatch[3])))

  let rgbMatch = cssString.findAll(rgbRegex)
  if len(rgbMatch) == 3:
      return cacheColor(cssString, rgb(hexToFloat(rgbMatch[0]),
                                       hexToFloat(rgbMatch[1]),
                                       hexToFloat(rgbMatch[2])))

  let rgbaMatch = cssString.findAll(rgbaRegex)
  if len(rgbaMatch) == 4:
      return cacheColor(cssString, rgba(hexToFloat(rgbaMatch[0]),
                                        hexToFloat(rgbaMatch[1]),
                                        hexToFloat(rgbaMatch[2]),
                                        hexToFloat(rgbaMatch[3])))


  warn "'" & cssString & "' is not yet a supported/valid color format."

  return rgb(0,0,0)
