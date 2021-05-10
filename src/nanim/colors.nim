import nanovg, nre, tables, strutils, nanim/logging, sequtils


let colorsCache = newTable[string, Color]()

proc cacheColor(name: string, color: Color): Color {.inline.} =
  colorsCache[name] = color
  return color


proc newColor*(r, g, b: int, a: float = 1.0): Color {.inline.} =
  return cacheColor("rgb(" & $r & "," & $g & "," & $b & "," & $a & ")", rgba(r.float/255.0, g.float/255.0, b.float/255.0, a))


let
  hexRegex = re("[#]?([0-9a-fA-F]{2})")
  rgbRegex = re("([+-]?[0-9]*[.]?[0-9]+)")


func hexToFloat(hexString: string): float {.inline.} =
  return fromHex[int](hexString).toFloat()


proc newColor*(cssString: string): Color =
  if colorsCache.hasKey(cssString):
    return colorsCache[cssString]

  if cssString.contains("rgb"):
    let rgbaMatch = cssString.findAll(rgbRegex)
    if len(rgbaMatch) == 4:
      return cacheColor(cssString, rgba(parseFloat(rgbaMatch[0])/255.0,
                                        parseFloat(rgbaMatch[1])/255.0,
                                        parseFloat(rgbaMatch[2])/255.0,
                                        parseFloat(rgbaMatch[3])))

    elif len(rgbaMatch) == 3:
      return cacheColor(cssString, rgb(parseFloat(rgbaMatch[0])/255.0,
                                       parseFloat(rgbaMatch[1])/255.0,
                                       parseFloat(rgbaMatch[2])/255.0))

  else:
    let hexMatch = cssString.findAll(hexRegex)
    if len(hexMatch) == 3:
      return cacheColor(cssString, rgb(hexToFloat(hexMatch[0])/255.0,
                                       hexToFloat(hexMatch[1])/255.0,
                                       hexToFloat(hexMatch[2])/255.0))
    elif len(hexMatch) >= 4:
      return cacheColor(cssString, rgba(hexToFloat(hexMatch[0])/255.0,
                                        hexToFloat(hexMatch[1])/255.0,
                                        hexToFloat(hexMatch[2])/255.0,
                                        hexToFloat(hexMatch[3])/255.0))



  warn "'" & cssString & "' is not yet a supported/valid color format."
  return rgba(0,0,0,0)


func colorsFromCoolors*(link: string): seq[Color] {.inline.} =
  result = link.split("-").map(newColor)
