
import
  glm,
  nanovg,
  nanim/core


type
  Line* = ref object of Entity


proc init*(line: Line) =
  init(line.Entity)
  line.tension = 0
  line.style.strokeWidth = 5.0


proc newLine*(startPoint: Vec3 = vec3(0, 0, 0), endPoint: Vec3 = vec3(0, 10, 0)): Line =
  new(result)
  result.init()

  result.points = @[startPoint, endPoint]

proc newLine*(startPoint: Vec2 = vec2(0, 0), endPoint: Vec3 = vec2(0, 10)): Line =
  newLine(vec3(startPoint.x, startPoint.y, 0.0), vec3(startPoint.x, startPoint.y, 0.0))

proc newLine*(x1, y1, x2, y2: float): Line =
  newLine(vec3(x1, y1, 0.0), vec3(x2, y2, 0.0))

method draw*(line: Line, scene: Scene) =
  let context = scene.context

  context.beginPath()
  context.moveTo(line.points[0].x, line.points[0].y)
  context.lineTo(line.points[1].x, line.points[1].y)
  context.closePath()

  scene.applyStyle(line.style)
