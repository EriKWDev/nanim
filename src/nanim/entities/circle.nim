
import
  glm,
  math


import entity


type Circle = ref object of Entity


proc init*(circle: Circle) =
  init(circle.Entity)
  circle.tension = 0


proc newCircle*(radius: float = 100.0): Entity =
  new(result)
  result.init()

  let segments = 9.0

  var angle = 0.0
  while angle < 2 * PI:
    result.points.add(vec3(cos(angle), sin(angle), 0.0) * radius)
    angle = angle + 2 * PI / segments

  result.cornerRadius = radius
