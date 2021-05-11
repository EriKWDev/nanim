import os, streams, parsexml, strutils, nanim, tables, re


proc styleToTable(styleString: string): TableRef[string, string] =
  result = newTable[string, string]()

  let splitString = styleString.strip().split(";")

  for s in splitString:
    let keyValue = s.split(":")
    if len(keyValue) < 2:
      continue
    result[keyValue[0]] = keyValue[1]


let translateRegex = re"[\s]*?([+-]?[0-9]*[.]?[0-9]+)[\s]*?"

proc parseSVGPartStart(ventity: VEntity, name: string, attributes: TableRef[string, string]) =
  case name:
    of "path":
      let child = newVEntityFromPathString(attributes["d"])
      child.style = ventity.style.deepCopy()
      ventity.add(child)
    of "g":
      if attributes.hasKey("style"):
        let
          styleTable = styleToTable(attributes["style"])
          style = newStyle()

        if styleTable.hasKey("fill"):
          style.fillColor = newColor(styleTable["fill"])
          style.fillMode = smSolidColor

        if styleTable.hasKey("stroke"):
          style.strokeColor = newColor(styleTable["stroke"])
          style.strokeMode = smSolidColor

        if styleTable.hasKey("stroke-width"):
          style.strokeWidth = styleTable["stroke-width"].parseFloat()

        ventity.style = style

      if attributes.hasKey("transform"):
        let
          t = attributes["transform"]
          tmatches = t.findAll(translateRegex)
          (dx, dy) = (tmatches[0].parseFloat(), tmatches[1].parseFloat())

        ventity.move(-dx, -dy)




    else:
      echo name, ": ", attributes


proc newVEntityFromSVGFile*(path: string): VEntity =
  result = newVEntityFromPathString("")

  var s = newFileStream(path, fmRead)
  var x: XmlParser
  x.open(s, path)

  while true:
    x.next()

    case x.kind
    of xmlElementOpen:
      var
        attributes = newTable[string, string]()
        name = x.elementName

      while x.kind != xmlElementClose:
        x.next()
        if x.kind == xmlAttribute:
          attributes[x.attrKey] = x.attrValue

      result.parseSVGPartStart(name, attributes)

    of xmlElementStart:
      result.parseSVGPartStart(x.elementName, newTable[string, string]())
    of xmlElementEnd: discard
    of xmlEof: break # end of file reached

    else: discard # ignore other events

  x.close()


when isMainModule:
  let p = os.joinPath(os.getAppDir(), "test.svg")
  var a = newVEntityFromSVGFile(p)
  a.moveTo(600, 500)
  a.pscale(1.5)

  let
    scene = newScene()
    bg = newColor("#FFFFFF")

  scene.background = proc(scene: Scene) = scene.fill(bg)

  scene.add(a)

  render(scene)
