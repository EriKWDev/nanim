
import
  glm,
  math,
  nanim/core


type
  Engon* = ref object of Entity


proc init*(engon: Engon) =
  init(engon.Entity)
  engon.tension = 0
  engon.cornerRadius = 0


proc newEngon*(n: float, radius: float = 100.0): Engon =
  new(result)
  result.init()

  if n <= 2:
    return

  var angle = 0.0
  for i in 1..n.int:
    result.points.add(vec3(cos(angle), sin(angle), 0.0) * radius)
    angle = angle + 2 * PI / n


proc newRegularTriangle*(radius: float = 100.0): Engon = newEngon(3, radius)
proc newPentagon*(radius: float = 100.0): Engon = newEngon(5, radius)
proc newHexagon*(radius: float = 100.0): Engon = newEngon(6, radius)
proc newBestagon*(radius: float = 100.0): Engon = newEngon(6, radius)
proc newHeptagon*(radius: float = 100.0): Engon = newEngon(7, radius)
proc newOctagon*(radius: float = 100.0): Engon = newEngon(8, radius)
