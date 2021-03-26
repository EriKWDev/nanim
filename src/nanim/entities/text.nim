
import cairo


import entity


type
  Text* = ref object of Entity
    message*: string
    font*: string
    fontSize*: float
    fontOptions*: FontOptions



proc init*(text: Text) =
  init(text.Entity)
  text.message = ""


proc newText*(message: string = "",
              fontSize: float = 12,
              font: string = "montserrat"): Text =

  new(result)
  result.init()
  result.message = message
  result.fontSize = fontSize
  result.font = font


method draw*(text: Text, context: ptr Context) =
  context.selectFontFace(text.font, FontSlantNormal, FontWeightNormal)

  context.newPath()
  context.textPath(text.message)
  context.closePath()

  context.setLineWidth(20)
  context.setColor(rgb(230, 26, 94))
  context.stroke()
  context.setColor(rgb(255, 56, 116))
  context.fill()
