
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
    cornerRadius*: float

    position*: Position
    rotation*: float
    scaling*: Scale


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  points:   " & $(entity.points.len) & "\n" &
    "  position: " & $(entity.position) & "\n" &
    "  scale:    " & $(entity.scaling) & "\n" &
    "  rotation: " & $(entity.rotation) & "\n" &
    "  tension:  " & $(entity.tension)


proc drawPointsWithTension*(context: Context, points: seq[Vec], tension: float = 0.5) =
  if len(points) < 2: return

  context.moveTo(points[0].x, points[0].y)

  let controlScale = tension / 0.5 * 0.175
  let numberOfPoints = len(points)

  for i in 0..high(points):
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


proc drawPointsWithRoundedCornerRadius*(context: Context, points: seq[Vec], cornerRadius: float = 20) =
    if len(points) < 2: return

    var p1 = points[0]

    let lastPoint = points[high(points)]
    let midPoint = vec2((p1.x + lastPoint.x) / 2.0, (p1.y + lastPoint.y) / 2.0)

    context.moveTo(midPoint.x, midPoint.y)
    for i in 1..high(points):
      let p2 = points[i]

      context.arcTo(p1.x, p1.y, p2.x, p2.y, cornerRadius)
      p1 = p2

    context.arcTo(p1.x, p1.y, midPoint.x, midPoint.y, cornerRadius)


method draw*(entity: Entity, context: Context) {.base.} =
  context.fillColor(rgb(255, 56, 116))
  context.strokeColor(rgb(230, 26, 94))
  context.strokeWidth(20)
  context.beginPath()


  if entity.tension > 0:
    context.drawPointsWithTension(entity.points, entity.tension)
  else:
    context.drawPointsWithRoundedCornerRadius(entity.points, entity.cornerRadius)

  context.closePath()
  context.stroke()
  context.fill()


func init*(entity: Entity) =
  entity.points = @[]
  entity.tension = 0.0
  entity.cornerRadius = 20.0
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scaling = vec3(1.0, 1.0, 1.0)


func newEntity*(points: seq[Vec3[float]]): Entity =
  new(result)
  result.init()
  result.points = points


func show*(entity: Entity): Tween =
  var interpolators: seq[proc(t: float)]
  let delta = vec3(10.0, 0.0, 0.0)

  let
    startValue = entity.position.deepCopy() - delta
    endValue = entity.position.deepCopy()

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


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

    startCornerRadius = entity.cornerRadius.deepCopy()
    endCornerRadius: float = startCornerRadius * d

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startCornerRadius, endCornerRadius, t)
    entity.points = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.points = endValue
  entity.cornerRadius = endCornerRadius

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


proc setTension*(entity: Entity, tension: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.tension.deepCopy()
    endValue = tension

  let interpolator = proc(t: float) =
    entity.tension = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.tension = endValue

  result = newTween(interpolators, defaultEasing, defaultDuration)


proc setCornerRadius*(entity: Entity, cornerRadius: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.cornerRadius.deepCopy()
    endValue = cornerRadius

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.cornerRadius = endValue

  result = newTween(interpolators, defaultEasing, defaultDuration)
