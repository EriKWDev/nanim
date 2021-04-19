
import
  glm,
  math,
  nanovg,
  nanim/core


type
  Point* = ref object of Entity
    radius*: float


proc init*(point: Point) =
  init(point.Entity)
  point.tension = 0
  point.radius = 10.0


proc newPoint*(radius: float = 10.0): Point =
  new(result)
  result.init()

  result.radius = radius


proc newDot*(radius: float = 10.0): Point = newPoint(radius)


proc newPivot*(): Entity = newEntity()
proc newAnchor*(): Entity = newEntity()


method draw*(point: Point, scene: Scene) =
  let context = scene.context
  context.beginPath()
  context.circle(0, 0, point.radius)
  context.closePath()
  scene.applyStyle(point.style)
