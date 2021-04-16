
import
  glm,
  math,
  nanim/core


type
  Point* = ref object of Entity


proc init*(point: Point) =
  init(point.Entity)
  point.tension = 0


proc newPoint*(radius: float = 10.0): Point =
  new(result)
  result.init()

  let segments = 9.0

  var angle = 0.0
  while angle < 2 * PI:
    result.points.add(vec3(cos(angle), sin(angle), 0.0) * radius)
    angle = angle + 2 * PI / segments

  result.cornerRadius = radius


proc newDot*(radius: float = 10.0): Point = newPoint(radius)


proc newPivot*(): Entity = newEntity()
proc newAnchor*(): Entity = newEntity()
