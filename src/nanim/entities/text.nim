
import
  nanovg,
  nanim/core


type
  Text* = ref object of Entity
    message*: string
    font*: string
    fontSize*: float
    horizontalAlignment*: HorizontalAlign
    verticalAlignment*: VerticalAlign


let defaultTextPaint* = newStyle(fillMode=smSolidColor, fillColor=rgb(255, 255, 255))

proc init*(text: Text) =
  init(text.Entity)
  text.message = ""
  text.style.apply(defaultTextPaint)


method draw*(text: Text, scene: Scene) =
  let context = scene.context
  context.textAlign(text.horizontalAlignment, text.verticalAlignment)
  context.fontSize(text.fontSize * 10)
  context.fontFace(text.font)

  context.setStyle(text.style)
  context.beginPath()
  discard context.text(0, 0, text.message)
  context.closePath()


proc newText*(message: string = "",
              fontSize: float = 8,
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



