
import
  nanovg,
  nanim/core,
  nanim/animation,
  nanim/logging
from strutils import toLowerAscii


type
  Text* = ref object of Entity
    message*: string
    font*: cstring
    fontSize*: float
    horizontalAlignment*: HorizontalAlign
    verticalAlignment*: VerticalAlign

  TextBox* = ref object of Text
    width*: float


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

  scene.setStyle(text.style)
  context.beginPath()
  discard context.text(0, 0, text.message)
  context.closePath()


proc newText*(message: string = "",
              fontSize: float = 8,
              font: string = "montserrat",
              horizontalAlignment: HorizontalAlign = haCenter,
              verticalAlignment: VerticalAlign = vaBaseline): Text =
  when not defined(release):
    if numberOfFontsLoaded <= 0:
      warn "Using a TextBox without having any fonts in the fonts directory."

  new(result)
  result.init()
  result.message = message
  result.fontSize = fontSize
  result.font = font.toLowerAscii
  result.horizontalAlignment = horizontalAlignment
  result.verticalAlignment = verticalAlignment


proc init*(textBox: TextBox) =
  init(textBox.Text)
  textBox.width = 100


proc newTextBox*(message: string = "",
                 width: float = 100,
                 fontSize: float = 8,
                 font: string = "montserrat",
                 horizontalAlignment: HorizontalAlign = haCenter,
                 verticalAlignment: VerticalAlign = vaBaseline): TextBox =
  new(result)
  result.init()
  result.width = width
  result.message = message
  result.fontSize = fontSize
  result.font = font.toLowerAscii
  result.horizontalAlignment = horizontalAlignment
  result.verticalAlignment = verticalAlignment


method draw*(textBox: TextBox, scene: Scene) =
  when not defined(release):
    if numberOfFontsLoaded <= 0:
      warn "Using a TextBox without having any fonts in the fonts directory."

  let context = scene.context
  context.textAlign(textBox.horizontalAlignment, textBox.verticalAlignment)
  context.fontSize(textBox.fontSize * 10)
  context.fontFace(textBox.font)

  scene.setStyle(textBox.style)
  context.beginPath()
  context.textBox(0, 0, textBox.width, textBox.message)
  context.closePath()


proc setFontSize*(entity: Text|TextBox, fontSize: float = 8): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.fontSize.deepCopy()
    endValue = fontSize

  let interpolator = proc(t: float) =
    entity.fontSize = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.fontSize = endValue

  result = newTween(interpolators)
