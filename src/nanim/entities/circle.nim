
import
  glm,
  math


import entity


type Circle = ref object of Entity


proc init*(self: Circle) =
  init(self.Entity)


proc newCircle*(radius: float = 100.0): Entity =
  new(result)
  result.init()

  let segments = 9

  var angle = 0.0
  while angle < 2 * PI:
    result.points.add(vec3(cos(angle), sin(angle), 0.0) * radius)
    angle = angle + 2 * PI / segments.float
