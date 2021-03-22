
import sequtils, math


import
  glm,
  nanovg,
  ../animation/tween,
  ../animation/easings


type
  Position* = Vec3[float]
  Scale* = Vec3[float]

  Context* = NVGContext

  Entity* = ref object of RootObj
    points*: seq[Vec3[float]]
    tension*: float

    position*: Position
    rotation*: float
    scaling*: Scale


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  position: " & $(entity.position) & "\n" &
    "  rotation: " & $(entity.rotation)


proc drawPointsWithTension(context: Context, points: seq[Vec], tension: float = 0.5) =
  if len(points) < 2: return

  context.moveTo(points[0].x, points[0].y)

  let controlScale = tension / 0.5 * 0.175
  let numberOfPoints = len(points)

  for i in 0..len(points) - 1:
    let points_before = points[(i - 1 + numberOfPoints) mod numberOfPoints]
    let point = points[i]

    let pointAfter = points[(i + 1) mod numberOfPoints]
    let pointAfter2 = points[(i + 2) mod numberOfPoints]

    let p4 = pointAfter

    let di = vec2(pointAfter.x - points_before.x, pointAfter.y - points_before.y)
    let p2 = vec2(point.x + controlScale * di.x, point.y + controlScale * di.y)

    let diPlus1 = vec2(pointAfter2.x - points[i].x, pointAfter2.y - points[i].y)

    let p3 = vec2(pointAfter.x - controlScale * diPlus1.x, pointAfter.y - controlScale * diPlus1.y)

    context.bezierTo(p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)


method draw*(entity: Entity, context: Context) {.base.} =
  context.fillColor(rgb(255, 56, 116))
  context.strokeColor(rgb(230, 26, 94))
  context.strokeWidth(20)
  context.beginPath()

  context.drawPointsWithTension(entity.points, entity.tension)

  context.closePath()
  context.stroke()
  context.fill()


func init*(entity: Entity) =
  entity.points = @[]
  entity.tension = 0.5
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scaling = vec3(1.0, 1.0, 1.0)


func newEntity*(points: seq[Vec3[float]]): Entity =
  new(result)
  result.init()
  result.points = points


func move*(entity: Entity,
           dx: float = 0.0,
           dy: float = 0.0,
           dz: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]
  let delta = vec3(dx, dy, dz)

  let
    startValue = entity.position.deepCopy()
    endValue = startValue + delta

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func stretch*(entity: Entity,
              dx: float = 0.0,
              dy: float = 0.0,
              dz: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = startValue * vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func scale*(entity: Entity, d: float = 0.0): Tween =
  return entity.stretch(d, d, d)


proc pscale*(entity: Entity, d: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.points.deepCopy()
    endValue = entity.points.map(proc(point: Vec3[float]): Vec3[float] = point * d)

  let interpolator = proc(t: float) =
    entity.points = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.points = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


type
  AngleMode* = enum
    amDegrees, amRadians


func rotate*(entity: Entity, dangle: float = 0.0, mode: AngleMode = amDegrees): Tween =
  var interpolators: seq[proc(t: float)]
  var angle: float

  case mode:
  of amDegrees: angle = math.degToRad(dangle)
  of amRadians: angle = dangle

  let
    startValue = entity.rotation.deepCopy()
    endValue = startValue + angle

  let interpolator = proc(t: float) =
    entity.rotation = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.rotation = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func setTension*(entity: Entity, tension: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.tension.deepCopy()
    endValue = startValue + tension

  let interpolator = proc(t: float) =
    entity.tension = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.tension = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)