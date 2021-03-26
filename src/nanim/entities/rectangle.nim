

import glm


import entity


type
  Rectangle* = ref object of Entity


proc init*(rectangle: Rectangle) =
  init(rectangle.Entity)
  rectangle.tension = 0
  rectangle.cornerRadius = 0


proc newRectangle*(width: float = 120, height: float = 70, centered: bool = true, cornerRadius: float = 0): Rectangle =
  new(result)
  result.init()

  var points = @[
      vec3[float](0, 0, 0), vec3[float](width, 0, 0),
      vec3[float](width, height, 0), vec3[float](0, height, 0)
  ]

  if centered:
    for i in 0..high(points):
      points[i] = points[i] - vec3(width/2.0, height/2.0, 0.0)

  result.points = points
  result.cornerRadius = cornerRadius


proc newSquare*(side: float = 100, centered: bool = true): Rectangle = newRectangle(side, side, centered)
