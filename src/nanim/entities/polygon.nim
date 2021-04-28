
import
  glm,
  nanim/core


type
  Polygon* = ref object of Entity


proc init*(polygon: Polygon) =
  init(polygon.Entity)
  polygon.tension = 0.0
  polygon.cornerRadius = 0.0


proc newPolygon*(points: seq[Vec3[float]]): Polygon =
  new(result)
  result.init()
  result.points = points
