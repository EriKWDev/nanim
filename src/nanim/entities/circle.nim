
import
  glm,
  math


import entity


proc newCircle*(radius: float = 100.0): Entity =
  var points: EntityPoints = @[]

  let segments = 9

  var angle = 0.0
  while angle < 2 * PI:
    points.add(vec3(cos(angle), sin(angle), 0.0) * radius)
    angle = angle + 2 * PI / segments.float

  result = newEntity(points)
