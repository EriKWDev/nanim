
import nanovg


import entity


type
  Text* = ref object of Entity
    message*: string
    font*: string
    fontSize*: float
    horizontalAlignment*: HorizontalAlign
    verticalAlignment*: VerticalAlign


proc init*(text: Text) =
  init(text.Entity)
  text.message = ""


proc newText*(message: string = "",
              fontSize: float = 12,
              font: string = "montserrat",
              horizontalAlignment: HorizontalAlign = haCenter,
              verticalAlignment: VerticalAlign = vaBaseline): Text =
  new(result)
  result.init()
  result.message = message
  result.fontSize = fontSize
  result.font = font
  result.horizontalAlignment = horizontalAlignment
  result.verticalAlignment = verticalAlignment


method draw*(text: Text, context: NVGContext) =
  context.textAlign(text.horizontalAlignment, text.verticalAlignment)
  context.fontSize(text.fontSize * 10)
  context.fontFace(text.font)

  context.strokeColor(rgb(230, 26, 94))
  context.fillColor(rgb(255, 56, 116))
  context.strokeWidth(20)

  discard context.text(0, 0, text.message)

  context.stroke()
  context.fill()

