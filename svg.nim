import os, streams, parsexml, strutils


func parseSVGPath(path: string): seq[float] =
  var i = 0
  while true:
    if Whitespace.contains(path[i]) or path[i] == ',':
      inc i
      continue

    case path[i]

      of 'M'


func parseSVGPartStart(name: string, attributes: string): seq[float] {.inline.} =
    case name:
      of "path":
        result = parseSVGPath(attributes)
      else:
        result = @[]


proc parseSVGFileToPathSequence*(path: string): seq[float] =
  result = newSeq[float]()

  var s = newFileStream(path, fmRead)
  var x: XmlParser
  x.open(s, path)

  #[
    xmlElementStart,   ## ``<elem>``
    xmlElementEnd,     ## ``</elem>``
    xmlElementOpen,    ## ``<elem
    xmlAttribute,      ## ``key = "value"`` pair
    xmlElementClose,   ## ``>``
  ]#

  while true:
    x.next()

    case x.kind
    of xmlElementOpen:
      var
        attributes = ""
        name = x.elementName

      while x.kind != xmlElementClose:
        x.next()
        if x.kind == xmlAttribute:
          attributes &= x.attrKey & "=" & x.attrValue & ";"

      result &= parseSVGPartStart(name, attributes)

    of xmlElementStart: result &= parseSVGPartStart(x.elementName, "")
    of xmlElementEnd: discard
    of xmlEof: break # end of file reached

    else: discard # ignore other events

  x.close()


when isMainModule:
  let p = os.joinPath(os.getAppDir(), "test.svg")
  echo parseSVGFileToPathSequence(p)